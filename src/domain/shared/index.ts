/**
 * Shared subdomain barrel
 */

export type { CelebrationEvent } from './celebration-event';
export { getCelebrationTitle, getCelebrationSubtitle } from './celebration-event';

export type { ProgramAvailabilityStatus } from './program-availability';
export {
  getProgramAvailability,
  sortedPrograms,
  nextUpcomingProgram,
  parseProgramDate,
  formatProgramStartDate,
} from './program-availability';

export type { WODTemplateType } from './wod-template-type';
export {
  wodTemplateTypeFrom,
  wodTemplateTypeDisplayName,
  wodTemplateTypeRequiresTimer,
} from './wod-template-type';
