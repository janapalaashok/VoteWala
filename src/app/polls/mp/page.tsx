import { PollsListing } from "@/components/PollsListing";

export const dynamic = "force-dynamic";
export const metadata = { title: "MP Polls" };

export default async function MpPolls({ searchParams }: { searchParams: Promise<{ phase?: string; district?: string }> }) {
  return <PollsListing type="PARLIAMENTARY" basePath="/polls/mp" searchParams={await searchParams} />;
}
