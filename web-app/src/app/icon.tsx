import { ImageResponse } from "next/og";
import { AppSharkMark } from "@/components/ui/app-shark-mark";

export const size = { width: 512, height: 512 };
export const contentType = "image/png";

export default function Icon() {
  return new ImageResponse(
    <AppSharkMark size={512} />,
    { ...size }
  );
}
