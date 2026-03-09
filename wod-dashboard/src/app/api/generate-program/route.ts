import { NextRequest, NextResponse } from 'next/server';
import { ALL_EXERCISES } from '@/data/exercise-catalog';
import { validateProgram } from '@/lib/program-validator';
import { ProgramFormData } from '@/types/program';

const PROXY_URL = 'https://workout-proxy.sundeefundee.workers.dev/generate-workout';

export async function POST(request: NextRequest) {
  const { prompt, durationWeeks, sessionsPerWeek, difficulty, category } = await request.json();

  if (!prompt || typeof prompt !== 'string') {
    return NextResponse.json({ error: 'Prompt is required' }, { status: 400 });
  }

  // Subset of exercises relevant to category
  const exerciseSubset = ALL_EXERCISES.slice(0, 60).join(', ');

  const systemPrompt = `You are a strength and conditioning coach creating structured multi-week training programs for the Sundee Fundee fitness app.

Generate a complete program in JSON format matching this exact schema:
{
  "description": "string - program description",
  "phases": [
    {
      "id": "string - slug like 'phase-1'",
      "name": "string",
      "goal": "string",
      "weekRange": [startWeek, endWeek]
    }
  ],
  "weeks": [
    {
      "week": number,
      "phaseId": "string - references a phase id, or null",
      "isTestWeek": boolean,
      "sessions": [
        {
          "sessionId": "string - like 'w1-s1'",
          "sessionName": "string",
          "sessionType": "strength|hypertrophy|power|conditioning|recovery",
          "focus": "string - e.g. 'Upper Body'",
          "exercises": [
            {
              "exercise": "string - must be a real exercise name from the catalog",
              "variant": "string or null",
              "sets": number or [min, max] or "AMRAP",
              "reps": number or [min, max] or "AMRAP" or "string for time-based",
              "percent1RM": number (decimal 0.0-1.0) or null,
              "restMinutes": number or null,
              "notes": "string or null",
              "bodyweightOnly": boolean
            }
          ]
        }
      ]
    }
  ],
  "cycleAdjustmentProfile": null
}

CONSTRAINTS:
- Exactly ${durationWeeks} weeks
- Exactly ${sessionsPerWeek} sessions per week
- Difficulty: ${difficulty}
- Category: ${category}
- Use valid exercise names from this catalog: ${exerciseSubset}
- Apply periodization: progressive overload, appropriate deload weeks (every 3-4 weeks)
- Phase progression should make sense (e.g., base → build → peak, or hypertrophy → strength → power)
- Each session should have 4-8 exercises
- Use "phaseId" (lowercase d), "sessionId" (lowercase d) - NOT "phaseID" or "sessionID"
- sets and reps can be: a number (e.g. 3), an array [min, max] (e.g. [8, 12]), "AMRAP", or a string (e.g. "30s")
- bodyweightOnly should be true for exercises like Push-Up, Air Squat, Burpee, etc.

Respond with ONLY valid JSON, no markdown fences, no explanation.`;

  try {
    const response = await fetch(PROXY_URL, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        model: 'gemini-3.1-flash-lite-preview',
        contents: [{ role: 'user', parts: [{ text: prompt }] }],
        systemInstruction: { parts: [{ text: systemPrompt }] },
        generationConfig: { responseMimeType: 'application/json' },
      }),
    });

    if (!response.ok) {
      const errorText = await response.text();
      console.error('Program generation proxy error:', errorText);
      return NextResponse.json({ error: 'AI generation failed' }, { status: 502 });
    }

    const data = await response.json();
    const text = data.candidates?.[0]?.content?.parts?.[0]?.text;
    if (!text) {
      return NextResponse.json({ error: 'No response from AI' }, { status: 502 });
    }

    const generated = JSON.parse(text.trim());

    // Quick validation — create a temporary full program to validate
    const tempProgram: ProgramFormData = {
      id: 'temp-validation',
      name: 'Temp',
      category: category || 'general',
      description: generated.description || '',
      durationWeeks: durationWeeks,
      sessionsPerWeek: sessionsPerWeek,
      difficulty: difficulty || 'intermediate',
      status: 'draft',
      phases: generated.phases || [],
      weeks: generated.weeks || [],
      cycleAdjustmentProfile: generated.cycleAdjustmentProfile || null,
    };

    const errors = validateProgram(tempProgram);
    if (errors.length > 0) {
      console.warn('AI-generated program has validation warnings:', errors);
      // Don't reject — let the user fix in editor
    }

    return NextResponse.json(generated);
  } catch (error) {
    console.error('Program generation error:', error);
    return NextResponse.json({ error: 'Failed to generate program' }, { status: 500 });
  }
}
