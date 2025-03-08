class GrowingGoat extends ResizableGoat;

/**
 * if the mutator should be selectable in the Custom Game Menu.
 */
static function bool IsUnlocked( optional out array<AchievementDetails> out_CachedAchievements )
{
	return True;
}

/**
 * See super.
 */
function ModifyPlayer(Pawn Other)
{
	local GGGoat goat;

	goat = GGGoat( other );
	super.ModifyPlayer( other );

	IntiComponent(goat, 1.f, true);
}