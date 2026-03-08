import WODEditor from '@/components/WODEditor';

interface EditorPageProps {
  params: Promise<{ date: string }>;
}

export default async function EditorPage({ params }: EditorPageProps) {
  const { date } = await params;
  return <WODEditor date={date} />;
}
