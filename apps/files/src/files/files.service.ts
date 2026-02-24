import { Inject, Injectable, NotFoundException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { ClientProxy } from '@nestjs/microservices';
import {
  S3Client,
  PutObjectCommand,
  GetObjectCommand,
  DeleteObjectCommand,
} from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import { EVENTS, FileUploadedPayload } from '@noton/shared';
import { PrismaService } from '../prisma/prisma.service';
import { RegisterFileDto } from './dto/register-file.dto';

@Injectable()
export class FilesService {
  private readonly s3: S3Client;
  private readonly bucket: string;

  constructor(
    private readonly prisma: PrismaService,
    private readonly config: ConfigService,
    @Inject('NATS_SERVICE') private readonly nats: ClientProxy,
  ) {
    this.bucket = config.get<string>('MINIO_BUCKET', 'noton-files');
    this.s3 = new S3Client({
      region: 'us-east-1',
      endpoint: config.get<string>('MINIO_ENDPOINT', 'http://localhost:9000'),
      credentials: {
        accessKeyId: config.get<string>('MINIO_ACCESS_KEY', 'minioadmin'),
        secretAccessKey: config.get<string>('MINIO_SECRET_KEY', 'minioadmin'),
      },
      forcePathStyle: true,
    });
  }

  async getUploadPresignUrl(filename: string, mimeType: string) {
    const key = `uploads/${Date.now()}-${filename.replace(/[^a-zA-Z0-9._-]/g, '_')}`;
    const url = await getSignedUrl(
      this.s3,
      new PutObjectCommand({
        Bucket: this.bucket,
        Key: key,
        ContentType: mimeType,
      }),
      { expiresIn: 300 },
    );
    return { url, bucketKey: key };
  }

  async getDownloadPresignUrl(id: string) {
    const file = await this.prisma.fileRecord.findUnique({ where: { id } });
    if (!file) throw new NotFoundException(`File ${id} not found`);
    const url = await getSignedUrl(
      this.s3,
      new GetObjectCommand({ Bucket: this.bucket, Key: file.bucketKey }),
      { expiresIn: 3600 },
    );
    return { url, file };
  }

  async register(dto: RegisterFileDto, uploaderId: string) {
    const file = await this.prisma.fileRecord.create({
      data: {
        uploaderId,
        workspaceId: dto.workspaceId,
        filename: dto.bucketKey.split('/').pop() ?? dto.originalName,
        originalName: dto.originalName,
        mimeType: dto.mimeType,
        size: dto.size,
        bucketKey: dto.bucketKey,
        isPublic: dto.isPublic ?? false,
      },
    });

    const payload: FileUploadedPayload = {
      fileId: file.id,
      workspaceId: file.workspaceId,
      uploaderId: file.uploaderId,
      mimeType: file.mimeType,
      bucketKey: file.bucketKey,
    };
    this.nats.emit(EVENTS.FILE_UPLOADED, payload).subscribe({
      error: (err: unknown) => console.error('[files] NATS emit failed:', err),
    });

    return file;
  }

  async findById(id: string) {
    const file = await this.prisma.fileRecord.findUnique({ where: { id } });
    if (!file) throw new NotFoundException(`File ${id} not found`);
    return file;
  }

  findByWorkspace(workspaceId: string) {
    return this.prisma.fileRecord.findMany({
      where: { workspaceId },
      orderBy: { createdAt: 'desc' },
    });
  }

  async delete(id: string) {
    const file = await this.findById(id);
    await this.s3.send(
      new DeleteObjectCommand({ Bucket: this.bucket, Key: file.bucketKey }),
    );
    return this.prisma.fileRecord.delete({ where: { id } });
  }
}
