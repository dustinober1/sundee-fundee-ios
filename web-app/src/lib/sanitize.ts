// web-app/src/lib/sanitize.ts
import sanitizeHtml from "sanitize-html";

const ALLOWED_TAGS = [
  "h1", "h2", "h3", "h4", "h5", "h6",
  "p", "br", "hr",
  "strong", "em", "u", "s", "code", "pre",
  "ul", "ol", "li",
  "a", "img",
  "blockquote",
  "table", "thead", "tbody", "tr", "th", "td",
  "div", "span",
];

const ALLOWED_ATTRIBUTES: Record<string, string[]> = {
  a: ["href", "title", "target", "rel"],
  img: ["src", "alt", "width", "height"],
  code: ["class"],
  pre: ["class"],
  div: ["class"],
  span: ["class"],
};

export function sanitize(html: string): string {
  return sanitizeHtml(html, {
    allowedTags: ALLOWED_TAGS,
    allowedAttributes: ALLOWED_ATTRIBUTES,
    allowedSchemes: ["http", "https", "mailto"],
  });
}
