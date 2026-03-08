import { NextRequest, NextResponse } from 'next/server';

const PROXY_URL = 'https://workout-proxy.sundeefundee.workers.dev/generate-workout';

export async function POST(request: NextRequest) {
  const { prompt } = await request.json();

  if (!prompt || typeof prompt !== 'string') {
    return NextResponse.json({ error: 'Prompt is required' }, { status: 400 });
  }

  const systemPrompt = `You are a strength and conditioning coach creating workouts for the Sundee Fundee fitness app.
Generate a structured workout in JSON format matching this schema:
{
  "title": "string - creative workout name",
  "description": "string - brief coaching notes",
  "templateType": "strength|amrap|emom|forTime|circuit",
  "timeCap": number or null (minutes, for AMRAP/EMOM/ForTime),
  "exercises": [
    {
      "exercise": "string - standard exercise name",
      "variant": "string or null",
      "sets": number,
      "reps": number or "string for time-based",
      "percent1RM": number or null (as decimal 0.0-1.0),
      "restMinutes": number or null,
      "notes": "string or null - coaching cues",
      "bodyweightOnly": boolean
    }
  ]
}
Respond with ONLY valid JSON, no markdown fences, no explanation.`;

  try {
    const response = await fetch(PROXY_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: 'gemini-3.1-flash-lite-preview',
        contents: [
          { role: 'user', parts: [{ text: prompt }] },
        ],
        systemInstruction: {
          parts: [{ text: systemPrompt }],
        },
        generationConfig: {
          responseMimeType: 'application/json',
        },
      }),
    });

    if (!response.ok) {
      const errorText = await response.text();
      console.error('Workout proxy error:', errorText);
      return NextResponse.json({ error: 'AI generation failed' }, { status: 502 });
    }

    const data = await response.json();

    // Extract text from Gemini response format
    const text = data.candidates?.[0]?.content?.parts?.[0]?.text;
    if (!text) {
      return NextResponse.json({ error: 'No response from AI' }, { status: 502 });
    }

    // Parse the JSON response
    const workout = JSON.parse(text.trim());
    return NextResponse.json(workout);
  } catch (error) {
    console.error('AI generation error:', error);
    return NextResponse.json({ error: 'Failed to generate workout' }, { status: 500 });
  }
}
