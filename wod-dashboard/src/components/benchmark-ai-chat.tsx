"use client";

import { useEffect, useRef, useState } from "react";

interface Message {
  role: "user" | "assistant";
  content: string;
  workoutDescription?: string;
  scoringTypeRaw?: string;
}

interface BenchmarkAIChatProps {
  benchmarkId: string;
  onApply: (workoutDescription: string, scoringTypeRaw: string) => void;
}

export function BenchmarkAIChat({ benchmarkId, onApply }: BenchmarkAIChatProps) {
  const [messages, setMessages] = useState<Message[]>([]);
  const [input, setInput] = useState("");
  const [isLoading, setIsLoading] = useState(false);
  const [isExpanded, setIsExpanded] = useState(false);
  const messagesEndRef = useRef<HTMLDivElement>(null);

  // Reset conversation when benchmark changes
  useEffect(() => {
    setMessages([]);
    setInput("");
    setIsLoading(false);
  }, [benchmarkId]);

  // Auto-scroll to bottom on new messages
  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [messages]);

  async function handleSend() {
    const text = input.trim();
    if (!text || isLoading) return;

    const userMessage: Message = { role: "user", content: text };
    const updatedMessages = [...messages, userMessage];
    setMessages(updatedMessages);
    setInput("");
    setIsLoading(true);

    try {
      const res = await fetch("/api/generate/benchmark", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          messages: updatedMessages.map((m) => ({
            role: m.role,
            content: m.content,
          })),
        }),
      });

      const data = await res.json();

      if (!res.ok) {
        setMessages((prev) => [
          ...prev,
          {
            role: "assistant",
            content: `Error: ${data.error ?? "Unknown error"}. Try again.`,
          },
        ]);
        return;
      }

      setMessages((prev) => [
        ...prev,
        {
          role: "assistant",
          content: `${data.workoutDescription}\n\nScoring: ${data.scoringTypeRaw}`,
          workoutDescription: data.workoutDescription,
          scoringTypeRaw: data.scoringTypeRaw,
        },
      ]);
    } catch (err) {
      setMessages((prev) => [
        ...prev,
        {
          role: "assistant",
          content: `Error: ${err instanceof Error ? err.message : "Network error"}. Try again.`,
        },
      ]);
    } finally {
      setIsLoading(false);
    }
  }

  return (
    <div className="mb-4 border border-navy/20 rounded overflow-hidden">
      {/* Toggle header */}
      <button
        type="button"
        onClick={() => setIsExpanded(!isExpanded)}
        className="w-full flex items-center justify-between px-3 py-2 bg-navy/5 hover:bg-navy/10 transition-colors text-sm font-medium text-navy/70"
      >
        <span>AI Assist</span>
        <span className="text-xs">{isExpanded ? "▲" : "▼"}</span>
      </button>

      {isExpanded && (
        <div className="p-3 space-y-3">
          {/* Messages */}
          {messages.length > 0 && (
            <div className="max-h-64 overflow-y-auto space-y-2">
              {messages.map((msg, i) => (
                <div key={i}>
                  <div
                    className={`text-sm rounded px-3 py-2 ${
                      msg.role === "user"
                        ? "bg-navy/10 text-navy"
                        : "bg-orange/10 text-navy"
                    }`}
                  >
                    <span className="font-medium text-xs block mb-1 text-navy/50">
                      {msg.role === "user" ? "You" : "AI"}
                    </span>
                    <span className="whitespace-pre-wrap">{msg.content}</span>
                  </div>
                  {msg.workoutDescription && msg.scoringTypeRaw && (
                    <button
                      type="button"
                      onClick={() =>
                        onApply(msg.workoutDescription!, msg.scoringTypeRaw!)
                      }
                      className="mt-1 text-xs bg-orange text-white px-2 py-1 rounded hover:bg-orange/90 transition-colors"
                    >
                      Apply to form
                    </button>
                  )}
                </div>
              ))}
              {isLoading && (
                <div className="text-sm text-navy/40 px-3 py-2">
                  Generating...
                </div>
              )}
              <div ref={messagesEndRef} />
            </div>
          )}

          {/* Input */}
          <div className="flex gap-2">
            <input
              type="text"
              value={input}
              onChange={(e) => setInput(e.target.value)}
              onKeyDown={(e) => {
                if (e.key === "Enter" && !e.shiftKey) {
                  e.preventDefault();
                  handleSend();
                }
              }}
              placeholder={
                messages.length === 0
                  ? "Enter exercises (e.g., back squat, pull-ups, box jumps)"
                  : "Refine (e.g., make it an AMRAP instead)"
              }
              disabled={isLoading}
              className="flex-1 border border-navy/20 rounded px-3 py-1.5 text-sm bg-white focus:outline-none focus:ring-1 focus:ring-navy/40 disabled:opacity-50"
            />
            <button
              type="button"
              onClick={handleSend}
              disabled={!input.trim() || isLoading}
              className="bg-orange text-white px-3 py-1.5 rounded text-sm font-medium hover:bg-orange/90 transition-colors disabled:opacity-40 disabled:cursor-not-allowed"
            >
              {messages.length === 0 ? "Generate" : "Send"}
            </button>
          </div>
        </div>
      )}
    </div>
  );
}
