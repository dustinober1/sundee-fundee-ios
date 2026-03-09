import ProgramEditor from '@/components/ProgramEditor';

export default async function ProgramEditorPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  return <ProgramEditor programId={id} />;
}
