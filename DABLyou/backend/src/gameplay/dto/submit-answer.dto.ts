import { IsInt, IsOptional, IsString, Min } from 'class-validator';

export class SubmitAnswerDto {
  @IsString()
  questionId!: string;

  @IsString()
  selectedAnswer!: string;

  @IsInt()
  @Min(0)
  responseTimeMs!: number;

  @IsOptional()
  @IsString()
  deviceOs?: string; // "android" | "ios" | "web" — detected automatically by Flutter
}
