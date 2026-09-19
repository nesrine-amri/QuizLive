-- Add city to User for advertiser analytics
ALTER TABLE "User" ADD COLUMN "city" TEXT;
CREATE INDEX "User_city_idx" ON "User"("city");

-- Add city + deviceOs to Answer for per-event analytics
ALTER TABLE "Answer" ADD COLUMN "city" TEXT;
ALTER TABLE "Answer" ADD COLUMN "deviceOs" TEXT;
CREATE INDEX "Answer_city_idx"     ON "Answer"("city");
CREATE INDEX "Answer_deviceOs_idx" ON "Answer"("deviceOs");
