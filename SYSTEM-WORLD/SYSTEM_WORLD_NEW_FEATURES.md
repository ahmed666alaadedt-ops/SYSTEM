# SYSTEM WORLD — NEW FEATURES & EXPANSION
## Version 1.1

**Project:** SYSTEM WORLD  
**Repository:** SYSTEM  
**Folder:** SYSTEM-WORLD  
**Document Type:** Design Specification  
**Status:** Approved design — implementation pending

---

## 1. Purpose and preservation rules

This document records approved expansions to the existing SYSTEM WORLD vision. It supplements `SYSTEM_MASTER_VISION.md`; it does not replace it.

Mandatory preservation rules:

- Do not delete, overwrite, or remove existing project files, systems, or approved ideas.
- Do not replace an existing feature with a new one unless the project owner explicitly approves that change.
- Preserve the four independent worlds and all previously approved concepts.
- Integrate systems where useful while keeping each world's identity and rules independent.
- Review dependencies before changing existing files.
- A feature is not considered implemented merely because it is documented. Mark it implemented only after development and testing.

## 2. The four independent worlds

The project retains four independent worlds:

1. Modern Realistic Virtual World.
2. Mythology and Ancient History World.
3. Fantasy World.
4. Greed Island World.

Each world has its own locations, history, characters, activities, rules, and progression. Shared technical systems may connect them where appropriate, but must not erase their independence.

## 3. World map, discovery, markers, and fast travel

Create an interactive map and exploration system with the following behavior:

- Regions become discoverable through exploration.
- Map information is revealed as the player explores.
- Discovered locations may include cities, villages, hospitals, clinics, shops, services, landmarks, and other important places.
- Discovering a region does not automatically activate every fast-travel point within it.
- Each fast-travel point must be reached and activated individually through an in-world interaction.
- Only activated points become available fast-travel destinations.
- Players can add, remove, and manage personal map markers.
- Important discovered locations, including medical facilities, should be identifiable on the map.
- Fast travel may be restricted during combat, certain missions, dangerous situations, or other conditions defined by the relevant world's rules.
- The map and navigation framework should support all four worlds while respecting each world's geography and rules.

## 4. Hospitals and medical facilities

Hospitals and medical facilities must be meaningful locations, discoverable through exploration and represented on the map when discovered.

### Modern Realistic Virtual World

Possible facilities and services include:

- Hospitals and emergency departments.
- Clinics and specialist medical centers.
- Doctors, nurses, and medical specialists.
- Ambulance and emergency response services.
- Diagnostic examinations and medical tests.
- Surgery and other medical procedures.
- Medication and treatment.
- Rehabilitation and recovery facilities.

### Mythology and Ancient History World

Provide doctors, healers, medical facilities, herbs, and treatments appropriate to the relevant civilization, culture, and historical period.

### Fantasy World

Provide fantasy hospitals, healers, magical treatment, healing potions, and recovery facilities consistent with the world's established rules.

### Greed Island World

Provide medical and healing services compatible with the island's rules, systems, and gameplay mechanics.

Medical services should differ by world; modern medicine, historical treatment, and magical healing must not be treated as interchangeable.

## 5. Persistent injuries and character medical status

Injuries must persist after combat and missions. A character must not automatically recover from every injury simply because an activity or mission has ended.

The game should provide a medical-status display that can communicate:

- Current injuries.
- Injury severity.
- Relevant symptoms or limitations.
- Whether urgent treatment is needed.
- Treatment in progress.
- Recovery or rehabilitation progress.

Possible severity levels:

- Minor.
- Moderate.
- Severe.
- Critical.

Depending on severity and injury type, consequences may include:

- Reduced movement speed or mobility.
- Reduced stamina or endurance.
- Limited combat performance.
- Difficulty using certain abilities or equipment.
- Restrictions on some activities.
- Worsening condition if the injury is ignored or aggravated.

The character may need first aid, a doctor, emergency care, hospitalization, surgery, medication, or rehabilitation. The required treatment must depend on the injury and the rules of the current world.

Treatment time, cost, availability, and recovery should be meaningful but balanced. The system should create consequences without making ordinary gameplay unnecessarily frustrating.

Death, revival, and any resulting consequences must follow the rules established for the relevant world.

## 6. Crime, law, and justice

Create a persistent law and justice system, particularly in the Modern Realistic Virtual World.

The system may include:

- Criminal acts and legal violations.
- Police patrols and investigations.
- Witnesses and evidence.
- Wanted status and pursuit.
- Arrest and detention.
- Legal proceedings or trials where appropriate.
- Sentencing and imprisonment.
- Fines, restitution, and compensation.
- Different laws and enforcement practices by region and world.

Consequences should depend on the type, severity, evidence, and circumstances of the offense, as well as the laws of the location. The system should avoid treating every offense identically.

## 7. Prison and consequences after release

Imprisonment must have meaningful consequences that can continue after release. Completing a prison sentence must not automatically erase the character's history or restore everyone's trust.

Possible consequences include:

- A persistent criminal record.
- Changes to public reputation.
- Loss of trust from certain NPCs.
- Rejection by some individuals, businesses, or organizations.
- Restrictions on selected jobs, services, or opportunities where appropriate.
- Hostility from victims, rivals, or people affected by the character's actions.
- Threats, pursuit, harassment, or attacks from specific enemies or criminal groups.
- Increased danger in particular neighborhoods or locations.

Reactions must be contextual, not universal. Not every person should recognize the character, reject them, or attack them. Responses should depend on the crime, its seriousness, local knowledge, relationships, faction interests, and the character's current reputation.

## 8. Reputation, social acceptance, and rebuilding trust

Create a persistent reputation system that allows NPCs, businesses, organizations, and communities to react to the character's history and behavior.

Reputation may affect:

- Trust and distrust.
- Social acceptance or rejection.
- Friendships and hostility.
- Trading and business opportunities.
- Employment and organizational membership.
- Access to selected locations or services.
- Relationships with lawful groups and criminal factions.

The character must have fair, meaningful ways to rebuild reputation over time. Depending on the world and circumstances, these may include:

- Helping individuals or communities.
- Completing positive tasks and responsibilities.
- Compensating victims or settling debts.
- Making restitution and fulfilling obligations.
- Demonstrating reliable behavior consistently.
- Resolving conflicts through appropriate in-world systems.

Reputation must not reset instantly. Recovery should depend on actions, time, severity of past behavior, and the reactions of affected people.

## 9. Independent AI NPC society

NPCs should have lives and behavior that do not revolve exclusively around the player.

NPC capabilities may include:

- Individual names, personalities, memories, and personal histories.
- Goals, ambitions, needs, and daily routines.
- Jobs, trade, buying, and selling.
- Exploration and combat where appropriate.
- Friendships, rivalries, families, and other relationships.
- Interactions with other NPCs.
- Reactions to player actions and reputation.
- Activities and changes that continue when the player is absent, subject to the simulation's technical limits.

NPCs should be able to form opinions based on events they know about. Information should spread through plausible channels rather than every NPC automatically knowing everything.

## 10. Public and secret auctions

Introduce public and secret auctions for items such as:

- Historical artifacts.
- Rare treasures and collectibles.
- Unique equipment.
- Valuable discoveries.
- Special or unusual objects.

Player activities may include attending auctions, bidding, buying, selling, collecting rare objects, discovering secret auctions, and interacting with organizers, collectors, and rival bidders.

Possible events include theft attempts, robbery, organized criminal attacks, secret negotiations, rival bidders, and attempts by criminal organizations to obtain valuable objects.

Auction events should connect naturally with the economy, NPC society, reputation, security, and law systems.

The concept may take broad inspiration from auction themes in *Hunter × Hunter*, while all designs, writing, assets, and implementation remain original.

## 11. Real-life SYSTEM progression and avatar connection

Connect suitable real-life development activities to the virtual character where technically and ethically appropriate.

Trainable areas may include:

- Physical strength.
- Fitness.
- Endurance.
- Concentration.
- Mental development.
- Discipline.

Appropriate real-life improvements may influence corresponding avatar development. The system must distinguish real-world trainable attributes from fictional supernatural powers.

Abilities such as Nen, teleportation, and other supernatural powers must retain their own fictional progression rules and must not be represented as real-life abilities.

## 12. Movement, combat, and skill experience

Use *Where Winds Meet* as a broad reference for the desired quality and feel of movement, exploration, responsive combat, martial arts, skills, and environmental interaction.

SYSTEM WORLD must retain its own original identity, designs, assets, animations, mechanics, and implementation. Do not copy proprietary source code or game assets.

## 13. Cross-system integration

Connect systems where their interaction creates coherent gameplay, while preserving each system's purpose and each world's independence.

Examples:

- The map helps an injured character locate a discovered hospital or medical facility.
- Injury severity affects movement and combat until suitable treatment and recovery.
- A criminal arrest may affect the character's record, reputation, relationships, and future opportunities.
- NPCs may respond to known criminal history or acts of restitution.
- A criminal group may attempt to steal a rare item during an auction.
- A character's actions may influence access to services, organizations, and locations.

These are design relationships, not a requirement that every event occur automatically. Each interaction must respect context, world rules, and gameplay balance.

## 14. Implementation and verification checklist

For each feature:

1. Review the existing repository and relevant files.
2. Identify related systems, dependencies, and existing behavior.
3. Document requirements and expected outcomes.
4. Preserve existing files and functionality.
5. Implement the feature using the project's established architecture.
6. Test normal, edge, and failure conditions.
7. Test interactions with connected systems.
8. Check performance, usability, and gameplay balance.
9. Verify that existing features still work.
10. Record the implementation and test status accurately.

Do not claim that a feature is implemented until the code exists and the relevant tests have passed.

## 15. Current document status

This document records approved design expansions for SYSTEM WORLD:

- Four independent worlds retained.
- World discovery, map navigation, and personal markers.
- Individually activated fast-travel points.
- Discoverable hospitals and medical facilities.
- Persistent injuries and visible medical status.
- Treatment, hospitalization, and recovery.
- Crime, law, arrest, and justice.
- Prison and post-release consequences.
- Criminal records, reputation, and social acceptance.
- Contextual threats and possible retaliation.
- Opportunities to rebuild reputation.
- Independent AI NPC society.
- Public and secret auctions.
- Real-life SYSTEM progression connected appropriately to the avatar.
- Movement, combat, and skill experience.
- Cross-system integration.

**Status:** Design approved; software implementation and testing are pending.

**Preservation notice:** This document supplements the existing SYSTEM WORLD vision. It must not be used to delete, replace, or disregard any previously approved project content.
