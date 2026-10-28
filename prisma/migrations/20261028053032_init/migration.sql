-- CreateEnum
CREATE TYPE "Role" AS ENUM ('USER', 'ADMIN');

-- CreateEnum
CREATE TYPE "ConstituencyType" AS ENUM ('ASSEMBLY', 'PARLIAMENTARY');

-- CreateEnum
CREATE TYPE "Reservation" AS ENUM ('GEN', 'SC', 'ST');

-- CreateEnum
CREATE TYPE "CandidateStatus" AS ENUM ('PENDING', 'VERIFIED', 'REJECTED');

-- CreateEnum
CREATE TYPE "PollStatus" AS ENUM ('DRAFT', 'PUBLISHED', 'CANCELLED');

-- CreateEnum
CREATE TYPE "ResultPolicy" AS ENUM ('LIVE', 'DELAYED', 'AFTER_CLOSE');

-- CreateTable
CREATE TABLE "User" (
    "id" TEXT NOT NULL,
    "name" TEXT,
    "email" TEXT,
    "emailVerified" TIMESTAMP(3),
    "image" TEXT,
    "role" "Role" NOT NULL DEFAULT 'USER',
    "locale" TEXT NOT NULL DEFAULT 'en',
    "phone" TEXT,
    "phoneVerifiedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "User_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Account" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "type" TEXT NOT NULL,
    "provider" TEXT NOT NULL,
    "providerAccountId" TEXT NOT NULL,
    "refresh_token" TEXT,
    "access_token" TEXT,
    "expires_at" INTEGER,
    "token_type" TEXT,
    "scope" TEXT,
    "id_token" TEXT,
    "session_state" TEXT,

    CONSTRAINT "Account_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Session" (
    "id" TEXT NOT NULL,
    "sessionToken" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "expires" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Session_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "VerificationToken" (
    "identifier" TEXT NOT NULL,
    "token" TEXT NOT NULL,
    "expires" TIMESTAMP(3) NOT NULL
);

-- CreateTable
CREATE TABLE "OtpChallenge" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "phone" TEXT NOT NULL,
    "codeHash" TEXT NOT NULL,
    "attempts" INTEGER NOT NULL DEFAULT 0,
    "expiresAt" TIMESTAMP(3) NOT NULL,
    "consumedAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "OtpChallenge_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Constituency" (
    "id" TEXT NOT NULL,
    "type" "ConstituencyType" NOT NULL,
    "number" INTEGER NOT NULL,
    "nameEn" TEXT NOT NULL,
    "nameTe" TEXT NOT NULL,
    "district" TEXT NOT NULL,
    "reservation" "Reservation" NOT NULL DEFAULT 'GEN',
    "parentId" TEXT,
    "sourceUrl" TEXT NOT NULL,

    CONSTRAINT "Constituency_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Candidate" (
    "id" TEXT NOT NULL,
    "constituencyId" TEXT NOT NULL,
    "nameEn" TEXT NOT NULL,
    "nameTe" TEXT NOT NULL,
    "partyEn" TEXT NOT NULL,
    "partyTe" TEXT NOT NULL,
    "electionYear" INTEGER NOT NULL,
    "photoUrl" TEXT,
    "sourceUrl" TEXT NOT NULL,
    "sourceLabel" TEXT NOT NULL,
    "status" "CandidateStatus" NOT NULL DEFAULT 'PENDING',
    "verifiedAt" TIMESTAMP(3),
    "verifiedById" TEXT,
    "isDemo" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Candidate_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Poll" (
    "id" TEXT NOT NULL,
    "constituencyId" TEXT NOT NULL,
    "questionEn" TEXT NOT NULL,
    "questionTe" TEXT NOT NULL,
    "pollDate" DATE NOT NULL,
    "opensAt" TIMESTAMP(3) NOT NULL,
    "closesAt" TIMESTAMP(3) NOT NULL,
    "status" "PollStatus" NOT NULL DEFAULT 'DRAFT',
    "resultPolicy" "ResultPolicy" NOT NULL DEFAULT 'AFTER_CLOSE',
    "publishDelayMinutes" INTEGER NOT NULL DEFAULT 0,
    "isDemo" BOOLEAN NOT NULL DEFAULT false,
    "createdById" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Poll_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "PollOption" (
    "id" TEXT NOT NULL,
    "pollId" TEXT NOT NULL,
    "candidateId" TEXT,
    "labelEn" TEXT,
    "labelTe" TEXT,
    "sortOrder" INTEGER NOT NULL DEFAULT 0,

    CONSTRAINT "PollOption_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Vote" (
    "id" TEXT NOT NULL,
    "pollId" TEXT NOT NULL,
    "optionId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Vote_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "PollReport" (
    "pollId" TEXT NOT NULL,
    "totalVotes" INTEGER NOT NULL,
    "tallies" JSONB NOT NULL,
    "generatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "PollReport_pkey" PRIMARY KEY ("pollId")
);

-- CreateTable
CREATE TABLE "AuditLog" (
    "id" TEXT NOT NULL,
    "actorId" TEXT,
    "action" TEXT NOT NULL,
    "entityType" TEXT NOT NULL,
    "entityId" TEXT,
    "metadata" JSONB,
    "ip" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "AuditLog_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "User_email_key" ON "User"("email");

-- CreateIndex
CREATE UNIQUE INDEX "User_phone_key" ON "User"("phone");

-- CreateIndex
CREATE UNIQUE INDEX "Account_provider_providerAccountId_key" ON "Account"("provider", "providerAccountId");

-- CreateIndex
CREATE UNIQUE INDEX "Session_sessionToken_key" ON "Session"("sessionToken");

-- CreateIndex
CREATE UNIQUE INDEX "VerificationToken_token_key" ON "VerificationToken"("token");

-- CreateIndex
CREATE UNIQUE INDEX "VerificationToken_identifier_token_key" ON "VerificationToken"("identifier", "token");

-- CreateIndex
CREATE INDEX "OtpChallenge_userId_createdAt_idx" ON "OtpChallenge"("userId", "createdAt");

-- CreateIndex
CREATE INDEX "OtpChallenge_phone_createdAt_idx" ON "OtpChallenge"("phone", "createdAt");

-- CreateIndex
CREATE INDEX "Constituency_nameEn_idx" ON "Constituency"("nameEn");

-- CreateIndex
CREATE UNIQUE INDEX "Constituency_type_number_key" ON "Constituency"("type", "number");

-- CreateIndex
CREATE INDEX "Candidate_status_idx" ON "Candidate"("status");

-- CreateIndex
CREATE UNIQUE INDEX "Candidate_constituencyId_electionYear_nameEn_key" ON "Candidate"("constituencyId", "electionYear", "nameEn");

-- CreateIndex
CREATE INDEX "Poll_status_opensAt_closesAt_idx" ON "Poll"("status", "opensAt", "closesAt");

-- CreateIndex
CREATE INDEX "Poll_pollDate_idx" ON "Poll"("pollDate");

-- CreateIndex
CREATE UNIQUE INDEX "PollOption_id_pollId_key" ON "PollOption"("id", "pollId");

-- CreateIndex
CREATE UNIQUE INDEX "PollOption_pollId_candidateId_key" ON "PollOption"("pollId", "candidateId");

-- CreateIndex
CREATE INDEX "Vote_pollId_createdAt_idx" ON "Vote"("pollId", "createdAt");

-- CreateIndex
CREATE UNIQUE INDEX "Vote_pollId_userId_key" ON "Vote"("pollId", "userId");

-- CreateIndex
CREATE INDEX "AuditLog_createdAt_idx" ON "AuditLog"("createdAt");

-- CreateIndex
CREATE INDEX "AuditLog_entityType_entityId_idx" ON "AuditLog"("entityType", "entityId");

-- AddForeignKey
ALTER TABLE "Account" ADD CONSTRAINT "Account_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Session" ADD CONSTRAINT "Session_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "OtpChallenge" ADD CONSTRAINT "OtpChallenge_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Constituency" ADD CONSTRAINT "Constituency_parentId_fkey" FOREIGN KEY ("parentId") REFERENCES "Constituency"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Candidate" ADD CONSTRAINT "Candidate_constituencyId_fkey" FOREIGN KEY ("constituencyId") REFERENCES "Constituency"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Poll" ADD CONSTRAINT "Poll_constituencyId_fkey" FOREIGN KEY ("constituencyId") REFERENCES "Constituency"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "PollOption" ADD CONSTRAINT "PollOption_pollId_fkey" FOREIGN KEY ("pollId") REFERENCES "Poll"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "PollOption" ADD CONSTRAINT "PollOption_candidateId_fkey" FOREIGN KEY ("candidateId") REFERENCES "Candidate"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Vote" ADD CONSTRAINT "Vote_pollId_fkey" FOREIGN KEY ("pollId") REFERENCES "Poll"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Vote" ADD CONSTRAINT "Vote_optionId_pollId_fkey" FOREIGN KEY ("optionId", "pollId") REFERENCES "PollOption"("id", "pollId") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Vote" ADD CONSTRAINT "Vote_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "PollReport" ADD CONSTRAINT "PollReport_pollId_fkey" FOREIGN KEY ("pollId") REFERENCES "Poll"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "AuditLog" ADD CONSTRAINT "AuditLog_actorId_fkey" FOREIGN KEY ("actorId") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- ---- Integrity constraints not expressible in the Prisma schema ----

-- A poll must close after it opens.
ALTER TABLE "Poll" ADD CONSTRAINT "Poll_close_after_open" CHECK ("closesAt" > "opensAt");
ALTER TABLE "Poll" ADD CONSTRAINT "Poll_delay_nonnegative" CHECK ("publishDelayMinutes" >= 0);

-- Only verified mobile numbers in E.164 Indian format are stored.
ALTER TABLE "User" ADD CONSTRAINT "User_phone_format" CHECK ("phone" IS NULL OR "phone" ~ '^\+91[6-9][0-9]{9}$');

-- Candidates must cite an https source.
ALTER TABLE "Candidate" ADD CONSTRAINT "Candidate_source_https" CHECK ("sourceUrl" LIKE 'https://%');

-- Votes are immutable: reject updates, and reject inserts outside the poll window
-- or against unpublished polls, using the database clock.
CREATE OR REPLACE FUNCTION votewala_guard_vote() RETURNS trigger AS $$
DECLARE
  p RECORD;
BEGIN
  IF TG_OP = 'UPDATE' THEN
    RAISE EXCEPTION 'votes are immutable' USING ERRCODE = 'P0001';
  END IF;
  SELECT "status", "opensAt", "closesAt" INTO p FROM "Poll" WHERE "id" = NEW."pollId";
  IF p."status" <> 'PUBLISHED' THEN
    RAISE EXCEPTION 'poll is not published' USING ERRCODE = 'P0001';
  END IF;
  IF now() < p."opensAt" OR now() >= p."closesAt" THEN
    RAISE EXCEPTION 'poll is not open' USING ERRCODE = 'P0001';
  END IF;
  NEW."createdAt" := now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER "Vote_guard"
  BEFORE INSERT OR UPDATE ON "Vote"
  FOR EACH ROW EXECUTE FUNCTION votewala_guard_vote();

-- Audit log is append-only.
CREATE OR REPLACE FUNCTION votewala_audit_append_only() RETURNS trigger AS $$
BEGIN
  RAISE EXCEPTION 'audit log is append-only' USING ERRCODE = 'P0001';
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER "AuditLog_append_only"
  BEFORE UPDATE OR DELETE ON "AuditLog"
  FOR EACH ROW EXECUTE FUNCTION votewala_audit_append_only();
