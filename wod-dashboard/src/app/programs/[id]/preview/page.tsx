import ProgramPreview from '@/components/ProgramPreview';

export default async function ProgramPreviewPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  return <ProgramPreview programId={id} />;
}
