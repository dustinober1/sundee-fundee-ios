"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.generateWorkout = generateWorkout;
const vertexai_1 = require("@google-cloud/vertexai");
async function generateWorkout(projectId, prompt, systemInstruction) {
    const vertexAI = new vertexai_1.VertexAI({ project: projectId, location: "us-central1" });
    const model = vertexAI.getGenerativeModel({ model: "gemini-flash-lite-latest" });
    const result = await model.generateContent({
        systemInstruction: { role: "system", parts: [{ text: systemInstruction }] },
        contents: [{ role: "user", parts: [{ text: prompt }] }],
        generationConfig: {
            responseMimeType: "application/json",
        },
    });
    const raw = result.response.candidates?.[0]?.content?.parts?.[0]?.text;
    if (!raw) {
        throw new Error("No response from AI model");
    }
    const cleaned = stripMarkdownFences(raw);
    let parsed;
    try {
        parsed = JSON.parse(cleaned);
    }
    catch {
        throw new Error("Failed to parse AI response as JSON");
    }
    if (!isValidWorkoutResponse(parsed)) {
        throw new Error("Invalid response structure from AI");
    }
    return parsed;
}
function stripMarkdownFences(text) {
    const trimmed = text.trim();
    if (trimmed.startsWith("```")) {
        const lines = trimmed.split("\n");
        lines.shift();
        if (lines[lines.length - 1]?.trim() === "```") {
            lines.pop();
        }
        return lines.join("\n");
    }
    return trimmed;
}
function isValidWorkoutResponse(data) {
    if (typeof data !== "object" || data === null)
        return false;
    const obj = data;
    return typeof obj.coachingSummary === "string" && Array.isArray(obj.exercises);
}
//# sourceMappingURL=ai.js.map