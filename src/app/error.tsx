"use client";

export default function Error({ reset }: { error: Error; reset: () => void }) {
  return (
    <div className="container-page flex min-h-[50vh] flex-col items-center justify-center py-20 text-center">
      <h1 className="text-2xl font-bold">Something went wrong · ఏదో పొరపాటు జరిగింది</h1>
      <button onClick={reset} className="btn-primary mt-8">Try again · మళ్ళీ ప్రయత్నించండి</button>
    </div>
  );
}
