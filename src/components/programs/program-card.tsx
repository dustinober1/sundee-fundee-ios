'use client';

import Link from 'next/link';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import type { Program } from '@/types';
import { motion } from 'framer-motion';
import { VARIANTS } from '@/lib/animations';

interface ProgramCardProps {
  program: Program;
}

export function ProgramCard({ program }: ProgramCardProps) {
  return (
    <Link href={`/programs/${program.id}`}>
      <motion.div
        whileHover="hover"
        whileTap="tap"
        variants={VARIANTS.scalePress}
      >
        <Card className="h-full hover:shadow-md transition-shadow">
          <CardHeader>
            <div className="flex justify-between items-start">
              <CardTitle className="text-lg">{program.name}</CardTitle>
              <Badge variant="secondary">{program.difficulty}</Badge>
            </div>
            <CardDescription>{program.description}</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="text-sm text-muted-foreground">
              {program.durationWeeks} weeks • {program.daysPerWeek} days/week
            </div>
          </CardContent>
        </Card>
      </motion.div>
    </Link>
  );
}
