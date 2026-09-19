-- Add youtubeUrl to Media so each channel can point to its own live stream
ALTER TABLE "Media" ADD COLUMN "youtubeUrl" TEXT;
