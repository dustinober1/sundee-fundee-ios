import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { WeightProgressChart } from '@/components/progress/weight-progress-chart';

export default function ProgressPage() {
  return (
    <div className="min-h-screen p-4 pb-20">
      <h1 className="text-2xl font-bold mb-4">Progress</h1>

      <Card>
        <CardHeader>
          <CardTitle>Weight Progress</CardTitle>
        </CardHeader>
        <CardContent>
          <WeightProgressChart />
        </CardContent>
      </Card>
    </div>
  );
}
