import Foundation

public struct ExerciseTechniqueCue: Sendable, Equatable {
    public let exerciseName: String
    public let setupCues: [String]
    public let commonMistakes: [String]
    public let regression: String?
}

/// Setup cues, common mistakes and a regression for movements a generated
/// workout is likely to put in front of someone mid-set.
///
/// Coverage is deliberately partial: `ActiveWorkoutView` simply shows nothing
/// when a cue is missing, so the library targets the movements that actually
/// land in a session's opening slots rather than every catalog entry.
public enum ExerciseTechniqueLibrary {
    private static let aliases: [String: String] = [
        "Bench Press": "Flat Barbell Bench Press",
        "Romanian Deadlift": "Romanian Deadlift (No Straps)"
    ]

    /// Internal rather than private so tests can validate the whole table
    /// instead of a hand-maintained sample of it.
    static let cues: [String: ExerciseTechniqueCue] = [
        "Back Squat": ExerciseTechniqueCue(
            exerciseName: "Back Squat",
            setupCues: [
                "Set the bar across upper back, not the neck.",
                "Brace before each rep and keep ribs stacked.",
                "Sit between the heels with knees tracking over toes."
            ],
            commonMistakes: [
                "Rushing the descent before the brace is set.",
                "Letting knees cave inward on the drive up."
            ],
            regression: "Use a goblet squat or box squat to rehearse the pattern."
        ),
        "Goblet Squat": ExerciseTechniqueCue(
            exerciseName: "Goblet Squat",
            setupCues: [
                "Hold the weight close to the chest.",
                "Keep elbows tucked between the knees.",
                "Press the floor away through the whole foot."
            ],
            commonMistakes: [
                "Letting the weight drift forward.",
                "Collapsing the chest at the bottom."
            ],
            regression: "Use bodyweight squats or a lighter dumbbell."
        ),
        "Flat Barbell Bench Press": ExerciseTechniqueCue(
            exerciseName: "Flat Barbell Bench Press",
            setupCues: [
                "Set eyes under the bar before unracking.",
                "Pin shoulder blades back and down.",
                "Touch the bar to the lower chest with forearms vertical."
            ],
            commonMistakes: [
                "Bouncing the bar off the chest.",
                "Letting elbows flare straight out."
            ],
            regression: "Use dumbbell bench press or push-ups."
        ),
        "Dumbbell Bench Press": ExerciseTechniqueCue(
            exerciseName: "Dumbbell Bench Press",
            setupCues: [
                "Start with dumbbells over the chest.",
                "Keep wrists stacked over elbows.",
                "Lower with control until upper arms are near the bench."
            ],
            commonMistakes: [
                "Letting dumbbells drift behind the shoulders.",
                "Losing even pressure through both feet."
            ],
            regression: "Use a lighter pair or a floor press."
        ),
        "Romanian Deadlift (No Straps)": ExerciseTechniqueCue(
            exerciseName: "Romanian Deadlift (No Straps)",
            setupCues: [
                "Start tall with the bar close to thighs.",
                "Hinge hips back while keeping a soft knee bend.",
                "Keep the bar close as hamstrings load."
            ],
            commonMistakes: [
                "Turning the hinge into a squat.",
                "Reaching the bar away from the body."
            ],
            regression: "Use dumbbells and shorten the range."
        ),
        "Dumbbell Row": ExerciseTechniqueCue(
            exerciseName: "Dumbbell Row",
            setupCues: [
                "Brace with a steady torso.",
                "Pull elbow toward the back pocket.",
                "Pause briefly with shoulder blade pulled back."
            ],
            commonMistakes: [
                "Twisting the torso to start the pull.",
                "Shrugging the shoulder toward the ear."
            ],
            regression: "Use a supported row or lighter dumbbell."
        ),
        "Kettlebell Swing": ExerciseTechniqueCue(
            exerciseName: "Kettlebell Swing",
            setupCues: [
                "Hike the bell back like a football snap.",
                "Drive hips forward to float the bell.",
                "Keep arms relaxed and ribs down."
            ],
            commonMistakes: [
                "Squatting the bell instead of hinging.",
                "Lifting with the shoulders."
            ],
            regression: "Practice kettlebell deadlifts before swinging."
        ),
        "Push-Up": ExerciseTechniqueCue(
            exerciseName: "Push-Up",
            setupCues: [
                "Set hands under shoulders.",
                "Keep body in one long line.",
                "Lower chest between the hands with control."
            ],
            commonMistakes: [
                "Letting hips sag or pike up.",
                "Cutting reps short at the top or bottom."
            ],
            regression: "Use an incline push-up at a bench or rack."
        ),
        "Plank Hold": ExerciseTechniqueCue(
            exerciseName: "Plank Hold",
            setupCues: [
                "Set elbows directly under the shoulders.",
                "Squeeze glutes and tuck the ribs toward the hips.",
                "Hold one straight line from ear to heel."
            ],
            commonMistakes: [
                "Letting hips sag toward the floor.",
                "Holding the breath instead of breathing steadily."
            ],
            regression: "Drop to a knee plank and keep the same straight line."
        ),
        "Side Plank Hold": ExerciseTechniqueCue(
            exerciseName: "Side Plank Hold",
            setupCues: [
                "Stack the top shoulder over the bottom elbow.",
                "Lift the hips until the body forms one line.",
                "Keep the head in line with the spine."
            ],
            commonMistakes: [
                "Letting the bottom hip drift toward the floor.",
                "Rolling the chest forward out of the side position."
            ],
            regression: "Bend the bottom knee and hold from the knee instead of the foot."
        ),
        "Superman Hold": ExerciseTechniqueCue(
            exerciseName: "Superman Hold",
            setupCues: [
                "Lie face down with arms reaching overhead.",
                "Lift chest, arms and legs a few inches together.",
                "Keep the neck long and eyes down."
            ],
            commonMistakes: [
                "Cranking the head up to lift higher.",
                "Bending the knees to raise the legs."
            ],
            regression: "Lift only the upper body, keeping the legs down."
        ),
        "Pallof Press": ExerciseTechniqueCue(
            exerciseName: "Pallof Press",
            setupCues: [
                "Stand side-on to the anchor with the band at chest height.",
                "Brace hard, then press both hands straight out.",
                "Resist the pull toward the anchor throughout."
            ],
            commonMistakes: [
                "Letting the torso rotate toward the anchor.",
                "Standing so close that there is no band tension."
            ],
            regression: "Step closer to the anchor to reduce the rotational demand."
        ),
        "Band Dead Bug": ExerciseTechniqueCue(
            exerciseName: "Band Dead Bug",
            setupCues: [
                "Lie on your back holding the band overhead with arms locked.",
                "Press the lower back flat into the floor.",
                "Extend one leg at a time while keeping arms still."
            ],
            commonMistakes: [
                "Letting the lower back arch off the floor.",
                "Rushing the legs instead of moving with control."
            ],
            regression: "Keep the knees bent and lower the heel only part way."
        ),
        "Dumbbell Dead Bug": ExerciseTechniqueCue(
            exerciseName: "Dumbbell Dead Bug",
            setupCues: [
                "Hold the dumbbells straight over the shoulders.",
                "Press the lower back flat into the floor.",
                "Lower the opposite arm and leg together."
            ],
            commonMistakes: [
                "Losing the flat back as the leg extends.",
                "Letting the dumbbells drift back over the head."
            ],
            regression: "Move one limb at a time before combining them."
        ),
        "Band Wood Chop": ExerciseTechniqueCue(
            exerciseName: "Band Wood Chop",
            setupCues: [
                "Anchor the band high and stand side-on.",
                "Pull across the body with the arms staying long.",
                "Let the hips and ribs rotate together."
            ],
            commonMistakes: [
                "Chopping with the arms while the torso stays still.",
                "Rounding the back at the end of the pull."
            ],
            regression: "Shorten the range and use a lighter band."
        ),
        "Dumbbell Russian Twist": ExerciseTechniqueCue(
            exerciseName: "Dumbbell Russian Twist",
            setupCues: [
                "Sit tall and lean back to a stable angle.",
                "Hold the weight close to the chest.",
                "Rotate from the ribs, not the arms."
            ],
            commonMistakes: [
                "Swinging the weight side to side with momentum.",
                "Rounding the lower back as you lean away."
            ],
            regression: "Keep the heels down and use bodyweight only."
        ),
        "Bear Crawl": ExerciseTechniqueCue(
            exerciseName: "Bear Crawl",
            setupCues: [
                "Set hands under shoulders and knees under hips.",
                "Hover the knees an inch off the floor.",
                "Move opposite hand and foot together."
            ],
            commonMistakes: [
                "Letting the hips rock side to side.",
                "Raising the hips into a pike."
            ],
            regression: "Hold the hover in place before adding movement."
        ),
        "Suitcase Carry": ExerciseTechniqueCue(
            exerciseName: "Suitcase Carry",
            setupCues: [
                "Hold one weight at your side with a tall chest.",
                "Brace so the torso stays square.",
                "Walk with even, controlled steps."
            ],
            commonMistakes: [
                "Leaning away from the weight to counterbalance.",
                "Letting the shoulder hike toward the ear."
            ],
            regression: "Use a lighter weight and shorten the distance."
        ),
        "Kettlebell Rack Hold": ExerciseTechniqueCue(
            exerciseName: "Kettlebell Rack Hold",
            setupCues: [
                "Rest the bell on the forearm with the fist near the chin.",
                "Keep the elbow tucked against the ribs.",
                "Stand tall with the ribs stacked over the hips."
            ],
            commonMistakes: [
                "Letting the elbow drift away from the body.",
                "Leaning back to support the weight."
            ],
            regression: "Hold a lighter bell or shorten the hold."
        ),
        "Kettlebell Overhead Hold": ExerciseTechniqueCue(
            exerciseName: "Kettlebell Overhead Hold",
            setupCues: [
                "Press the bell up and lock the elbow.",
                "Stack the wrist over elbow over shoulder.",
                "Keep the ribs down and glutes engaged."
            ],
            commonMistakes: [
                "Arching the lower back to hold the bell up.",
                "Letting the wrist bend backward."
            ],
            regression: "Hold in a half-kneeling position for more stability."
        ),
        "Air Squat": ExerciseTechniqueCue(
            exerciseName: "Air Squat",
            setupCues: [
                "Stand with feet about shoulder width.",
                "Send the hips back and down together.",
                "Keep the chest tall and heels planted."
            ],
            commonMistakes: [
                "Letting the heels lift at the bottom.",
                "Knees caving inward on the way up."
            ],
            regression: "Squat down to a box or bench to learn the depth."
        ),
        "Front Squat": ExerciseTechniqueCue(
            exerciseName: "Front Squat",
            setupCues: [
                "Rest the bar on the front delts with elbows high.",
                "Brace before unracking and keep the ribs down.",
                "Drive up while keeping elbows lifted."
            ],
            commonMistakes: [
                "Dropping the elbows so the bar rolls forward.",
                "Letting the chest collapse out of the bottom."
            ],
            regression: "Use a goblet squat to rehearse the upright torso."
        ),
        "Dumbbell Front Squat": ExerciseTechniqueCue(
            exerciseName: "Dumbbell Front Squat",
            setupCues: [
                "Rack the dumbbells on the shoulders.",
                "Keep elbows up and the chest tall.",
                "Sit down between the hips with control."
            ],
            commonMistakes: [
                "Letting the dumbbells pull the chest forward.",
                "Cutting the depth short to keep the weight up."
            ],
            regression: "Switch to a goblet squat with a single weight."
        ),
        "Kettlebell Front Squat": ExerciseTechniqueCue(
            exerciseName: "Kettlebell Front Squat",
            setupCues: [
                "Rack one or two bells against the chest.",
                "Keep elbows tucked and wrists straight.",
                "Sit between the heels and stand tall."
            ],
            commonMistakes: [
                "Letting the bells drift away from the body.",
                "Rounding the upper back under the load."
            ],
            regression: "Use a single bell in the goblet position."
        ),
        "Split Squat": ExerciseTechniqueCue(
            exerciseName: "Split Squat",
            setupCues: [
                "Set a long stance with the back heel lifted.",
                "Drop the back knee straight toward the floor.",
                "Keep the front shin close to vertical."
            ],
            commonMistakes: [
                "Stepping too short so the front knee travels far forward.",
                "Letting the torso twist toward the front leg."
            ],
            regression: "Hold a rack or wall for balance."
        ),
        "Band Split Squat": ExerciseTechniqueCue(
            exerciseName: "Band Split Squat",
            setupCues: [
                "Stand on the band with the front foot.",
                "Hold the handles at the shoulders.",
                "Drop the back knee straight down."
            ],
            commonMistakes: [
                "Letting the band pull the chest forward.",
                "Pushing off the back foot instead of the front."
            ],
            regression: "Drop the band and use bodyweight only."
        ),
        "Band Squat": ExerciseTechniqueCue(
            exerciseName: "Band Squat",
            setupCues: [
                "Stand on the band with feet shoulder width.",
                "Hold the handles at shoulder height.",
                "Sit back and down against the band tension."
            ],
            commonMistakes: [
                "Letting the band round the upper back.",
                "Standing narrow so the band pulls the knees in."
            ],
            regression: "Step in closer on the band to reduce tension."
        ),
        "Glute Bridge": ExerciseTechniqueCue(
            exerciseName: "Glute Bridge",
            setupCues: [
                "Lie on your back with heels close to the hips.",
                "Push through the heels to lift the hips.",
                "Squeeze the glutes at the top without arching."
            ],
            commonMistakes: [
                "Pushing the hips up by arching the lower back.",
                "Letting the knees splay outward."
            ],
            regression: "Shorten the range and pause at the top."
        ),
        "Kettlebell Deadlift": ExerciseTechniqueCue(
            exerciseName: "Kettlebell Deadlift",
            setupCues: [
                "Set the bell between the mid-feet.",
                "Hinge the hips back and grip with a flat back.",
                "Stand by driving the floor away."
            ],
            commonMistakes: [
                "Squatting the bell up instead of hinging.",
                "Rounding the back to reach the handle."
            ],
            regression: "Raise the bell on a box to shorten the range."
        ),
        "Dumbbell Romanian Deadlift": ExerciseTechniqueCue(
            exerciseName: "Dumbbell Romanian Deadlift",
            setupCues: [
                "Start tall with the dumbbells against the thighs.",
                "Push the hips back with a soft knee bend.",
                "Lower until the hamstrings load, then stand tall."
            ],
            commonMistakes: [
                "Turning the hinge into a squat.",
                "Letting the dumbbells drift away from the legs."
            ],
            regression: "Shorten the range and stop above the knee."
        ),
        "Band Romanian Deadlift": ExerciseTechniqueCue(
            exerciseName: "Band Romanian Deadlift",
            setupCues: [
                "Stand on the band with a hip-width stance.",
                "Hinge the hips back keeping the band close.",
                "Stand tall and squeeze the glutes."
            ],
            commonMistakes: [
                "Bending the knees instead of hinging the hips.",
                "Rounding the back as tension increases."
            ],
            regression: "Step in closer on the band for less tension."
        ),
        "Incline Barbell Bench Press": ExerciseTechniqueCue(
            exerciseName: "Incline Barbell Bench Press",
            setupCues: [
                "Set the bench to a low incline.",
                "Pin the shoulder blades back and down.",
                "Touch the bar to the upper chest with control."
            ],
            commonMistakes: [
                "Setting the incline so steep it becomes a shoulder press.",
                "Bouncing the bar off the chest."
            ],
            regression: "Use dumbbells on the same incline."
        ),
        "Dumbbell Incline Press": ExerciseTechniqueCue(
            exerciseName: "Dumbbell Incline Press",
            setupCues: [
                "Set a low incline and sit back into the bench.",
                "Start with the dumbbells over the upper chest.",
                "Lower until the upper arms reach chest level."
            ],
            commonMistakes: [
                "Letting the dumbbells drift behind the shoulders.",
                "Flaring the elbows straight out to the sides."
            ],
            regression: "Use a lighter pair or press from a flat bench."
        ),
        "Band Chest Press": ExerciseTechniqueCue(
            exerciseName: "Band Chest Press",
            setupCues: [
                "Anchor the band behind you at chest height.",
                "Set the hands at the chest with elbows tucked.",
                "Press forward until the arms are long."
            ],
            commonMistakes: [
                "Letting the torso twist as one arm presses harder.",
                "Standing too close so the band goes slack."
            ],
            regression: "Step toward the anchor to reduce tension."
        ),
        "Band Incline Press": ExerciseTechniqueCue(
            exerciseName: "Band Incline Press",
            setupCues: [
                "Anchor the band low behind you.",
                "Start with hands at the lower chest.",
                "Press up and forward at an angle."
            ],
            commonMistakes: [
                "Pressing straight forward instead of upward.",
                "Letting the ribs flare as the arms extend."
            ],
            regression: "Use a lighter band and keep the range shorter."
        ),
        "Kettlebell Strict Press": ExerciseTechniqueCue(
            exerciseName: "Kettlebell Strict Press",
            setupCues: [
                "Start with the bell racked on the forearm.",
                "Brace the ribs down and squeeze the glutes.",
                "Press until the arm locks beside the ear."
            ],
            commonMistakes: [
                "Leaning back to start the press.",
                "Letting the wrist bend backward under the bell."
            ],
            regression: "Press from a half-kneeling position."
        ),
        "Kettlebell Floor Press": ExerciseTechniqueCue(
            exerciseName: "Kettlebell Floor Press",
            setupCues: [
                "Lie on your back with the bell over the chest.",
                "Keep the upper arm at about 45 degrees.",
                "Lower until the triceps touch the floor."
            ],
            commonMistakes: [
                "Bouncing the elbow off the floor.",
                "Letting the wrist bend back under the bell."
            ],
            regression: "Use a lighter bell and pause on the floor."
        ),
        "Incline Push-Up": ExerciseTechniqueCue(
            exerciseName: "Incline Push-Up",
            setupCues: [
                "Set hands on a bench or rack at shoulder width.",
                "Hold one line from ear to heel.",
                "Lower the chest to the surface with control."
            ],
            commonMistakes: [
                "Letting the hips sag as you lower.",
                "Cutting the range short at the bottom."
            ],
            regression: "Raise the surface higher to make it easier."
        ),
        "Pull-Up": ExerciseTechniqueCue(
            exerciseName: "Pull-Up",
            setupCues: [
                "Grip slightly wider than the shoulders.",
                "Start from a hang with the shoulders pulled down.",
                "Pull until the chin clears the bar."
            ],
            commonMistakes: [
                "Starting each rep from a loose, relaxed hang.",
                "Kicking the legs to generate momentum."
            ],
            regression: "Use a band for assistance or do inverted rows."
        ),
        "Chin-Up": ExerciseTechniqueCue(
            exerciseName: "Chin-Up",
            setupCues: [
                "Grip underhand at about shoulder width.",
                "Pull the shoulders down before bending the arms.",
                "Drive the elbows toward the ribs."
            ],
            commonMistakes: [
                "Swinging the hips to start the pull.",
                "Stopping short of the chin clearing the bar."
            ],
            regression: "Use a band for assistance or lower slowly from the top."
        ),
        "Barbell Row": ExerciseTechniqueCue(
            exerciseName: "Barbell Row",
            setupCues: [
                "Hinge forward with a flat back and soft knees.",
                "Pull the bar toward the lower ribs.",
                "Lower under control without standing up."
            ],
            commonMistakes: [
                "Standing up to heave the bar.",
                "Rounding the back as the set gets hard."
            ],
            regression: "Use a chest-supported row to remove the hinge."
        ),
        "Pendlay Row": ExerciseTechniqueCue(
            exerciseName: "Pendlay Row",
            setupCues: [
                "Set the torso roughly parallel to the floor.",
                "Reset the bar on the floor between reps.",
                "Pull explosively to the lower ribs."
            ],
            commonMistakes: [
                "Letting the torso rise as the bar comes up.",
                "Skipping the reset and turning it into a swing."
            ],
            regression: "Use a standard barbell row without the floor reset."
        ),
        "Kettlebell Row": ExerciseTechniqueCue(
            exerciseName: "Kettlebell Row",
            setupCues: [
                "Hinge forward and support the free hand.",
                "Pull the elbow toward the back pocket.",
                "Pause briefly with the shoulder blade pulled back."
            ],
            commonMistakes: [
                "Twisting the torso to start the pull.",
                "Shrugging the shoulder toward the ear."
            ],
            regression: "Use a lighter bell and support the chest."
        ),
        "Chest-Supported Row": ExerciseTechniqueCue(
            exerciseName: "Chest-Supported Row",
            setupCues: [
                "Lie chest-down on an inclined bench.",
                "Let the arms hang straight below the shoulders.",
                "Pull the elbows back and squeeze the shoulder blades."
            ],
            commonMistakes: [
                "Lifting the chest off the bench to move more weight.",
                "Pulling with the arms before the shoulder blades move."
            ],
            regression: "Use a lighter pair and pause at the top."
        ),
        "Band Row": ExerciseTechniqueCue(
            exerciseName: "Band Row",
            setupCues: [
                "Anchor the band at chest height.",
                "Step back until the band is taut with arms long.",
                "Pull the handles to the ribs, elbows close."
            ],
            commonMistakes: [
                "Leaning back to create the pull.",
                "Letting the shoulders shrug up as you row."
            ],
            regression: "Step toward the anchor to reduce tension."
        ),
        "Band Lat Pulldown": ExerciseTechniqueCue(
            exerciseName: "Band Lat Pulldown",
            setupCues: [
                "Anchor the band overhead.",
                "Start with the arms long and shoulders relaxed up.",
                "Pull the elbows down toward the ribs."
            ],
            commonMistakes: [
                "Leaning far back to finish the pull.",
                "Letting the elbows flare wide."
            ],
            regression: "Kneel further from the anchor for less tension."
        ),
        "Face Pull": ExerciseTechniqueCue(
            exerciseName: "Face Pull",
            setupCues: [
                "Set the cable at about face height.",
                "Pull toward the forehead with high elbows.",
                "Finish with the hands beside the ears."
            ],
            commonMistakes: [
                "Pulling to the chest instead of the face.",
                "Using so much weight the torso leans back."
            ],
            regression: "Lighten the load and pause at the end range."
        ),
        "Band Face Pull": ExerciseTechniqueCue(
            exerciseName: "Band Face Pull",
            setupCues: [
                "Anchor the band at about face height.",
                "Pull the band toward the forehead.",
                "Keep the elbows level with the hands."
            ],
            commonMistakes: [
                "Dropping the elbows into a row.",
                "Shrugging the shoulders as you pull."
            ],
            regression: "Step closer to the anchor for less tension."
        ),
        "Band High Pull": ExerciseTechniqueCue(
            exerciseName: "Band High Pull",
            setupCues: [
                "Stand on the band with a hip-width stance.",
                "Pull the handles up along the body.",
                "Lead with the elbows above the hands."
            ],
            commonMistakes: [
                "Letting the hands drift away from the body.",
                "Shrugging into the neck at the top."
            ],
            regression: "Pull only to chest height with a lighter band."
        ),
        "Burpee": ExerciseTechniqueCue(
            exerciseName: "Burpee",
            setupCues: [
                "Drop the hands down and kick the feet back together.",
                "Lower the chest with the body in one line.",
                "Step or jump the feet back in and stand tall."
            ],
            commonMistakes: [
                "Letting the hips sag when the chest hits the floor.",
                "Rushing so the standing position is never reached."
            ],
            regression: "Step the feet back one at a time instead of jumping."
        ),
        "Thruster": ExerciseTechniqueCue(
            exerciseName: "Thruster",
            setupCues: [
                "Rack the bar on the front delts with elbows high.",
                "Squat to full depth with an upright chest.",
                "Drive up and press overhead in one motion."
            ],
            commonMistakes: [
                "Pausing at the top of the squat before pressing.",
                "Letting the elbows drop so the bar rolls forward."
            ],
            regression: "Split it into a front squat and a strict press."
        ),
        "Dumbbell Thruster": ExerciseTechniqueCue(
            exerciseName: "Dumbbell Thruster",
            setupCues: [
                "Rack the dumbbells on the shoulders.",
                "Squat to depth keeping the chest tall.",
                "Drive up and press the weights overhead."
            ],
            commonMistakes: [
                "Pressing before the legs have finished driving.",
                "Letting the ribs flare at the overhead position."
            ],
            regression: "Do the squat and the press as separate movements."
        ),
        "Kettlebell Thruster": ExerciseTechniqueCue(
            exerciseName: "Kettlebell Thruster",
            setupCues: [
                "Rack the bells on the forearms with elbows tucked.",
                "Squat between the heels with a tall chest.",
                "Stand and press the bells overhead together."
            ],
            commonMistakes: [
                "Letting the bells pull the chest forward at the bottom.",
                "Leaning back to finish the press."
            ],
            regression: "Use a single bell, or split the squat and press apart."
        ),
        "Band Thruster": ExerciseTechniqueCue(
            exerciseName: "Band Thruster",
            setupCues: [
                "Stand on the band with the handles at the shoulders.",
                "Squat down against the band tension.",
                "Stand and press the handles overhead."
            ],
            commonMistakes: [
                "Letting the band pull the torso forward.",
                "Standing so wide the band cuts across the knees."
            ],
            regression: "Step in on the band to reduce tension."
        ),
        "Dumbbell Clean": ExerciseTechniqueCue(
            exerciseName: "Dumbbell Clean",
            setupCues: [
                "Start with the dumbbells hanging at the thighs.",
                "Hinge back, then drive the hips forward.",
                "Catch the weights on the shoulders with soft knees."
            ],
            commonMistakes: [
                "Curling the weights up with the arms.",
                "Catching with locked, stiff legs."
            ],
            regression: "Practise the hinge and shrug before adding the catch."
        ),
        "Dumbbell Pullover": ExerciseTechniqueCue(
            exerciseName: "Dumbbell Pullover",
            setupCues: [
                "Lie across or along a bench with the hips supported.",
                "Hold one dumbbell over the chest with both hands.",
                "Reach back over the head with a slight elbow bend."
            ],
            commonMistakes: [
                "Letting the ribs flare as the arms travel back.",
                "Bending and straightening the elbows to move the weight."
            ],
            regression: "Shorten the range and use a lighter dumbbell."
        ),
        "Dumbbell Renegade Row": ExerciseTechniqueCue(
            exerciseName: "Dumbbell Renegade Row",
            setupCues: [
                "Set up in a plank with a hand on each dumbbell.",
                "Widen the feet for a stable base.",
                "Row one dumbbell while the hips stay square."
            ],
            commonMistakes: [
                "Letting the hips rotate as you row.",
                "Setting the feet close so the body twists."
            ],
            regression: "Row from a knee plank, or do a plank hold first."
        ),
        "Dumbbell Snatch": ExerciseTechniqueCue(
            exerciseName: "Dumbbell Snatch",
            setupCues: [
                "Start with the dumbbell between the feet.",
                "Hinge back, then drive the hips through hard.",
                "Punch the hand up and lock out overhead."
            ],
            commonMistakes: [
                "Muscling the weight up with the arm.",
                "Rounding the back on the way down."
            ],
            regression: "Practise dumbbell cleans before going overhead."
        ),
        "Dumbbell Step-Up": ExerciseTechniqueCue(
            exerciseName: "Dumbbell Step-Up",
            setupCues: [
                "Set a box height that keeps the front thigh near parallel.",
                "Plant the whole front foot on the box.",
                "Drive through the front heel to stand tall."
            ],
            commonMistakes: [
                "Pushing off the trailing foot to get up.",
                "Letting the front knee cave inward."
            ],
            regression: "Lower the box and use bodyweight only."
        ),
        "Strict Press": ExerciseTechniqueCue(
            exerciseName: "Strict Press",
            setupCues: [
                "Set the bar on the front delts with elbows just ahead of it.",
                "Squeeze the glutes and keep the ribs stacked.",
                "Press the bar up and bring the head through at lockout."
            ],
            commonMistakes: [
                "Leaning back to start the press.",
                "Letting the bar drift forward away from the face."
            ],
            regression: "Press dumbbells, or press from a half-kneeling position."
        ),
        "Close Grip Bench Press": ExerciseTechniqueCue(
            exerciseName: "Close Grip Bench Press",
            setupCues: [
                "Grip about shoulder width, not narrower.",
                "Keep the elbows tucked close to the ribs.",
                "Touch the lower chest and press back up."
            ],
            commonMistakes: [
                "Gripping so narrow the wrists bend painfully.",
                "Flaring the elbows out as the set gets hard."
            ],
            regression: "Use dumbbells with a neutral grip."
        ),
        "Dumbbell Swing": ExerciseTechniqueCue(
            exerciseName: "Dumbbell Swing",
            setupCues: [
                "Hold one dumbbell by the head with both hands.",
                "Hike it back between the legs on a hinge.",
                "Snap the hips forward to float the weight up."
            ],
            commonMistakes: [
                "Squatting the weight up instead of hinging.",
                "Lifting with the shoulders to raise it higher."
            ],
            regression: "Practise dumbbell Romanian deadlifts first."
        ),
        "Band Squat to Press": ExerciseTechniqueCue(
            exerciseName: "Band Squat to Press",
            setupCues: [
                "Stand on the band with handles at the shoulders.",
                "Squat down keeping the chest tall.",
                "Stand and press the handles overhead in one motion."
            ],
            commonMistakes: [
                "Pressing before the legs finish driving.",
                "Letting the ribs flare at lockout."
            ],
            regression: "Split it into a band squat and a band overhead press."
        ),
        "Jumping Jack": ExerciseTechniqueCue(
            exerciseName: "Jumping Jack",
            setupCues: [
                "Start with feet together and arms at the sides.",
                "Jump the feet wide as the arms sweep overhead.",
                "Land softly through the whole foot."
            ],
            commonMistakes: [
                "Landing hard on straight legs.",
                "Letting the arms stop short of overhead."
            ],
            regression: "Step one foot out at a time instead of jumping."
        )
    ]

    public static func cue(for exerciseName: String) -> ExerciseTechniqueCue? {
        let canonical = canonicalExerciseID(exerciseName)
        return cues[canonical] ?? aliases[canonical].flatMap { cues[$0] }
    }
}
