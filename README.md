# Comp440Project3
Horror game

# AFTER SCHOOL
### Team Game Design Document

**Engine:** Godot 4  
**Genre:** Third-Person Horror  
**Team Size:** 3  
**Platform:** Web

**Team Members / System Owners**
- Evan Jones — Monster System
- Zion — School System
- Rhaiyn — Player System

---

# 1. Core Loop
**Author: Team**

**Explore the empty school to recover your belongings while avoiding a mysterious child entity, survive unpredictable bell-triggered chases, and use what you learn about the entity's behavior and the school's layout to escape.**

The player is a student who stayed after school and must recover several belongings before going home. While searching the building, they discover a mysterious child-like entity stalking the halls.

During normal exploration, the entity can disappear and reappear at valid locations whenever it is outside the player's view. At unpredictable times, the school bell rings and causes the entity to enter a Chase State from wherever it currently is.

During Chase State, the entity can no longer randomly relocate. It must physically navigate through the school toward the player until the bell stops.

The basic loop is:

**Explore → Find Belonging → Avoid/Observe Entity → Bell Rings → Survive Chase → Bell Stops → Continue Exploring → Escape**

---

# 2. The Systems
**Author: Team**

## Monster System
**Owner: Evan Jones**

### State It Owns

- Monster behavior state
- Monster location
- Monster target
- Monster movement speed
- Current stalking position
- Whether the monster is visible
- Whether the monster is currently chasing

The Monster System has two primary states:

**Stalking State:** The entity appears throughout the school and can relocate to valid stalking positions when the player cannot currently see it.

**Chase State:** The bell is ringing. The entity stops randomly relocating and physically follows valid paths toward the player.

### What It Does

The Monster System controls all behavior of the mysterious child entity.

During normal gameplay, it creates uncertainty by moving the entity between valid stalking positions while outside the player's view.

When the School System activates the bell, the Monster System enters Chase State and begins physically pursuing the player.

---

## School System
**Owner: Zion**

### State It Owns

- Bell active/inactive state
- Bell timing
- Bell duration
- School rooms
- Door states
- Valid stalking locations
- Valid paths through the school
- Environmental progression

### What It Does

The School System manages the environment and the unpredictable school bell.

The bell activates at uncertain intervals. When activated, it tells the Monster System to enter Chase State. When the bell stops, the monster returns to Stalking State.

The School System also determines which locations are valid for the entity to appear during Stalking and which physical paths are available during Chase.

---

## Player System
**Owner: Rhaiyn**

### State It Owns

- Player position
- Player movement
- Player current area
- Walking/running state
- Interaction state
- Collected belongings
- Objective progress

### What It Does

The Player System allows the player to move through and interact with the school.

The player explores the building, searches for belongings, moves through rooms and hallways, and runs from the entity during Chase State.

The Player System also provides the player's position to the Monster System during a chase so the entity knows where it needs to physically travel.

---

# 3. The Seams
**Author: Team**

## Seam 1 — School System → Monster System

**Value Written:** `bell_active`

**Writer:** School System

**Reader:** Monster System

The School System determines whether the bell is currently ringing.

The Monster System reads `bell_active` and decides which behavior state to use.

If:

**bell_active = false**

the entity uses Stalking State and can unpredictably relocate while outside the player's view.

If:

**bell_active = true**

the entity enters Chase State. It can no longer randomly relocate and must physically pursue the player.

### Freeze Test

If `bell_active` were frozen as false, the monster would never enter Chase State.

If it were frozen as true, the monster would remain in Chase State.

Therefore, this seam directly changes the monster's gameplay behavior.

---

## Seam 2 — Player System → Monster System

**Value Written:** `player_position`

**Writer:** Player System

**Reader:** Monster System

During Chase State, the Monster System reads the player's current position.

It uses the position to determine which direction and valid path it should follow to reach the player.

### Freeze Test

If `player_position` were frozen at one location, the monster would continue pursuing that location even after the player moved somewhere else.

Therefore, the player's state directly changes the Monster System's decisions.

---

## Seam 3 — Player System → School System

**Value Written:** `objective_progress`

**Writer:** Player System

**Reader:** School System

The Player System tracks how many required belongings the player has recovered.

The School System reads the player's objective progress and can use it to increase the intensity of the game by reducing the possible interval between bells as the player gets closer to escaping.

For example:

**Beginning:** Bells generally occur farther apart.

**Middle:** Bell intervals become shorter.

**End:** Bells can occur more frequently.

The exact time of the next bell is still unpredictable.

### Freeze Test

If objective progress were frozen at its starting value, the School System would never increase the frequency of possible bell events as the player progressed.

This seam ensures that all three systems interact with at least one other system.

---

# 4. The Familiar Thing
**Author: Team**

## Familiar Thing: School

The familiar thing in our game is a normal school after everyone has gone home.

A school is normally a predictable environment. Students recognize classrooms, lockers, hallways, desks, doors, fluorescent lights, and especially the school bell.

After school, those same familiar spaces become uncomfortable because they are empty, darker, and unusually quiet.

The most important familiar element is the **school bell**.

Normally, students associate the bell with moving between classes or the school day ending. It is predictable and harmless.

In our game, the bell becomes the signal that the entity is now actively hunting the player.

At the beginning of the game:

**Bell = familiar school sound**

As the player learns the monster's behavior:

**Bell = immediate danger**

The player is never explicitly told that the bell causes the chase. They learn the relationship by experiencing it.

## How It Changes What the Player Does

During normal exploration, the player's objective is to search the school and recover their belongings.

The moment the bell begins ringing, their priorities completely change.

**Before the bell:** Explore.

**During the bell:** Survive.

The player stops searching for belongings and begins thinking about escape routes, nearby hallways, corners, doors, and the possible location of the entity.

The school itself also becomes part of survival. The player learns which hallways connect, where corners lead, and which routes can create distance from the monster.

Something that normally helps organize a student's day—the school bell—becomes the sound they are most afraid to hear.

---

# 5. The Monster
**Author: Evan Jones**

The monster is a mysterious child-like entity that stalks the player throughout the school.

The entity resembles a student enough to belong in the environment, but its behavior reveals that something is wrong.

The monster follows three primary rules.

## Rule 1 — The Entity Can Relocate During Stalking

### State It Reads

**School System:** Valid stalking locations

While the bell is not ringing, the entity is in Stalking State.

When the player cannot currently see the entity, it is allowed to disappear and relocate to another valid stalking location in the school.

It may appear:

- At the end of a hallway
- Around a corner
- Inside a classroom
- Through a doorway
- In another valid stalking position

The player therefore cannot reliably keep track of exactly where the entity is.

### How the Player Figures It Out

The player may see the child standing at the end of a hallway.

They turn a corner or enter a classroom.

When they look back, the child is gone.

Later, the child appears somewhere else in the school.

After experiencing this several times, the player realizes that losing sight of the entity means losing track of its location.

---

## Rule 2 — The Bell Activates Chase State

### State It Reads

**School System:** `bell_active`

Whenever the school bell begins ringing, the entity immediately enters Chase State.

When the bell stops, the entity leaves Chase State and returns to Stalking State.

### How the Player Figures It Out

The player initially encounters the child standing or stalking at a distance.

Eventually:

**The bell rings.**

The entity's behavior immediately changes and it begins actively pursuing the player.

When the bell stops, the active chase ends.

After surviving multiple bell phases, the player learns:

**When the bell rings, run.**

No tutorial text directly tells the player this rule.

---

## Rule 3 — During Chase State, the Entity Must Physically Follow the Player

### State It Reads

**Player System:** Player position

**School System:** Valid school paths

During Stalking State, the entity can disappear and reappear.

During Chase State, it loses that ability.

Once the bell begins, the entity must physically travel from its current location toward the player's current position.

It must use the school's hallways, rooms, doors, and corners.

The entity cannot simply teleport ahead of the player during a chase.

### How the Player Figures It Out

During the first few chases, the player sees that the entity actually follows them.

If the player turns a corner, the monster must reach and turn that same corner.

If the player changes hallways, the monster must physically navigate to that hallway.

The player eventually learns that the bell makes the entity much more aggressive but also temporarily makes its movement more predictable.

---

## Predicted Scariest Moment

The scariest moment will be the beginning of an unexpected bell phase.

While exploring, the player does not reliably know where the entity is because it can relocate whenever it is outside the player's view.

The player might be walking through an empty hallway and have not seen the entity recently.

Because the game uses a close third-person camera, walls, corners, classrooms, and darkness prevent the player from seeing every nearby area.

The player approaches a hallway intersection.

Everything is quiet.

Then:

**The school bell suddenly rings.**

The player immediately knows that the entity has entered Chase State.

However, they do not know where the entity was when the chase began.

It could be:

- Behind the player
- Around the next corner
- Inside a nearby classroom
- Down another hallway
- On the opposite side of the school

The player may hear footsteps before they see the entity.

They must quickly decide which direction to run without knowing whether they are running away from the entity or directly toward it.

Eventually, the entity rounds one of the corners and the chase becomes visible.

This moment uses all three monster rules.

**Rule 1** means the player does not know where the entity was before the bell.

**Rule 2** causes the unpredictable bell to immediately begin the chase.

**Rule 3** means the entity must now physically approach the player from its unknown starting position.

The fear comes from two questions:

**When will the bell ring?**

**Where will the entity be when it does?**

---

# 6. Art Direction
**Author: Team**

## Art Style

Stylized low-poly 3D horror.

The school should look recognizable and believable without requiring photorealistic assets.

The environment should feel like a normal school that has become uncomfortable because everyone has left.

## Camera / Perspective

**Close third-person perspective.**

The camera sits behind and slightly above the player.

The camera is intentionally kept close so the player cannot easily see around every corner.

Walls and environmental geometry should block the player's view instead of allowing the camera to clip through them.

This allows the school layout to create natural blind spots.

The player should regularly wonder:

**"What's around that corner?"**

During a bell phase, that becomes:

**"Which corner is it coming from?"**

## Environment

The environment is a school after normal hours.

Important visual elements include:

- Long hallways
- Classrooms
- Lockers
- Desks
- Chairs
- Bulletin boards
- Whiteboards
- School posters
- Fluorescent ceiling lights
- Exit signs
- Classroom doors
- Windows

The school should not look abandoned.

It should look like students and teachers were there earlier that day.

That keeps the setting familiar.

## Lighting

Lighting should create limited information without making navigation frustrating.

The game will use:

- Dim hallways
- Fluorescent lights
- Dark corners
- Partially lit classrooms
- Long shadows
- Reduced long-distance visibility

The player should be able to navigate but should not always be able to clearly identify what is at the opposite end of a hallway.

## Environmental Occlusion

The school's layout will intentionally include:

- L-shaped hallways
- T-intersections
- Corners
- Doorways
- Classroom walls
- Lockers
- Other visual barriers

These prevent the third-person camera from revealing the entire environment.

They also provide opportunities for the monster to disappear during Stalking State.

## Monster Appearance

The entity appears as a mysterious child or student.

It should have:

- A smaller silhouette than the player
- Student-like clothing
- Limited facial detail
- Unnatural stillness
- A recognizable silhouette

The monster does not need gore or an extremely distorted appearance.

Its behavior should make it frightening.

During Stalking, it can stand completely still and watch the player.

During Chase, it suddenly moves quickly and aggressively.

## Animation

### Stalking

- Standing
- Watching
- Slight idle movement
- Minimal head movement

### Chase

- Running
- Faster movement
- Aggressive body posture

The sudden transition from stillness to movement should make the bell phase more frightening.

## UI

UI will remain minimal.

Possible UI:

- Interaction prompt
- Current objective
- Belongings collected

The game will **not** show:

- Monster position
- Minimap showing the monster
- Chase timer
- Time until next bell
- Monster health

The player should not know when the next bell will happen.

## Audio

Important sounds include:

- School bell
- Player footsteps
- Monster footsteps
- Doors
- Fluorescent light hum
- Environmental school ambience

The school bell is the most important sound in the game.

During Chase State, monster footsteps provide information about how close the entity may be without directly revealing its position.

---

# 7. Scope
**Author: Team**

## In Scope

### Small Interconnected School

The game will contain a limited portion of a school rather than an entire building.

The environment may contain:

- Main hallway
- Secondary hallway
- Several classrooms
- Larger room such as a library
- Entrance/exit

The level will include multiple corners and intersections to support both stalking and chasing.

### Third-Person Player

The player can:

- Walk
- Run
- Look around
- Interact
- Navigate rooms/hallways
- Collect belongings

### 3–4 Belongings

The player searches for several objects left throughout the school.

Possible objects include:

- Backpack
- Phone
- Jacket
- Keys

The keys may serve as the final required object before the player can leave.

### Stalking Monster

During Stalking State, the entity can appear at valid locations and relocate while outside the player's view.

### Bell System

The school bell activates at unpredictable intervals.

When the bell starts:

**Monster enters Chase State.**

When the bell stops:

**Monster returns to Stalking State.**

### Chase

During Chase State, the entity physically follows valid paths toward the player.

### Win Condition

Collect the required belongings and reach the school exit.

### Lose Condition

The entity catches the player during Chase State.

---

## Three Cuts

### Cut 1 — Advanced Sound Detection

The monster will not require an advanced system for detecting every sound the player makes.

If additional development time becomes available, player noise could influence the entity's stalking behavior.

**Why it is cut:** The bell and unpredictable monster location already provide the central horror experience.

### Cut 2 — Large School

Additional areas such as multiple floors, a gym, auditorium, courtyard, offices, or a large cafeteria can be removed.

**Why it is cut:** A smaller interconnected level makes the chase mechanic easier to develop and gives the team more time to improve the core systems.

### Cut 3 — Complex Inventory / Item Abilities

Collected belongings will primarily function as objectives.

Each item will not require a unique ability or complicated inventory interface.

**Why it is cut:** The focus of the project is learning the monster's rules and surviving the bell phases rather than inventory management.

---

# Core Design Goal

The most important experience in **After School** is the player's fear of hearing the school bell.

During exploration, the player should constantly understand that two pieces of information are intentionally unavailable:

**They do not know when the next bell will ring.**

**They do not know where the entity currently is.**

When the bell finally rings, both uncertainties become immediately important.

The player knows:

**The entity is coming.**

They just do not know:

**From where.**
