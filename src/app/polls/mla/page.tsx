import { PollsListing } from "@/components/PollsListing";

export const dynamic = "force-dynamic";
export const metadata = { title: "MLA Polls" };

export default async function MlaPolls({ searchParams }: { searchParams: Promise<{ phase?: string; district?: string }> }) {
  return <PollsListing type="ASSEMBLY" basePath="/polls/mla" searchParams={await searchParams} />;
}
