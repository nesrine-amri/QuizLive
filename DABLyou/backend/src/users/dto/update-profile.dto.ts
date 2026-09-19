import { IsDateString, IsEnum, IsOptional, IsString } from 'class-validator';
import { GenderDto } from '../../auth/dto/register.dto';

export class UpdateProfileDto {
  @IsOptional()
  @IsString()
  firstName?: string;

  @IsOptional()
  @IsString()
  lastName?: string;

  @IsOptional()
  @IsEnum(GenderDto)
  gender?: GenderDto;

  @IsOptional()
  @IsDateString()
  birthDate?: string;
}
