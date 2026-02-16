'use client';

import React from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import type { PhaseRecommendation } from '@/types';

interface RecommendationCardProps {
  recommendation: PhaseRecommendation;
}

export function RecommendationCard({ recommendation }: RecommendationCardProps) {
  return (
    <Card>
      <CardHeader>
        <CardTitle>Training Guidance</CardTitle>
      </CardHeader>
      <CardContent>
        <div className="p-4 bg-accent rounded-md">
          <h3 className="font-semibold mb-2">{recommendation.title}</h3>
          <p className="text-sm mb-3">{recommendation.description}</p>
          <div className="flex flex-wrap gap-2">
            <Badge variant="secondary">Focus: {recommendation.trainingFocus}</Badge>
            <Badge
              variant={
                recommendation.intensityRecommendation === 'peak'
                  ? 'destructive'
                  : recommendation.intensityRecommendation === 'high'
                    ? 'default'
                    : recommendation.intensityRecommendation === 'moderate'
                      ? 'secondary'
                      : 'outline'
              }
            >
              Intensity: {recommendation.intensityRecommendation}
            </Badge>
          </div>

          {recommendation.exercisesToEmphasize.length > 0 && (
            <div className="mt-3">
              <p className="text-xs uppercase text-muted-foreground mb-1">Focus on</p>
              <div className="flex flex-wrap gap-1">
                {recommendation.exercisesToEmphasize.map((exercise, idx) => (
                  <Badge key={idx} variant="outline" className="text-xs">
                    {exercise}
                  </Badge>
                ))}
              </div>
            </div>
          )}

          {recommendation.exercisesToAvoid.length > 0 && (
            <div className="mt-2">
              <p className="text-xs uppercase text-muted-foreground mb-1">Consider avoiding</p>
              <div className="flex flex-wrap gap-1">
                {recommendation.exercisesToAvoid.map((exercise, idx) => (
                  <Badge key={idx} variant="outline" className="text-xs bg-destructive/10">
                    {exercise}
                  </Badge>
                ))}
              </div>
            </div>
          )}
        </div>
      </CardContent>
    </Card>
  );
}
