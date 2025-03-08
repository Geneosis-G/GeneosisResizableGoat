class ResizableGoat extends GGMutator;

var array<PlayerController> mPCs;

/**
 * if the mutator should be selectable in the Custom Game Menu.
 */
static function bool IsUnlocked( optional out array<AchievementDetails> out_CachedAchievements )
{
	return False;
}

function IntiComponent(GGGoat goat, float initScale, bool resizeEnabled)
{
	local ResizableGoatComponent resizComp;

	if( goat != none )
	{
		resizComp=ResizableGoatComponent(GGGameInfo( class'WorldInfo'.static.GetWorldInfo().Game ).FindMutatorComponent(class'ResizableGoatComponent', goat.mCachedSlotNr));
		if(resizComp != none)
		{
			resizComp.UpdateComponent(initScale, resizeEnabled);
			if(goat.Controller != none)
			{
				GGPlayerInput( PlayerController(goat.Controller).PlayerInput ).RegisterKeyStateListner( KeyState );
			}
		}
	}
}

function KeyState( name newKey, EKeyState keyState, PlayerController PCOwner )
{
	local GGPlayerInputGame localInput;

	localInput = GGPlayerInputGame( PCOwner.PlayerInput );

	if( keyState == KS_Down )
	{
		if(localInput.IsKeyIsPressed("GBA_Special", string( newKey )))
		{
			SetTimer(2.f, false, NameOf(ModifyAllCameraZoom));
			mPCs.AddItem(PCOwner);
		}
	}
	else if( keyState == KS_Up )
	{
		if(localInput.IsKeyIsPressed("GBA_Special", string( newKey )))
		{
			ClearTimer(NameOf(ModifyAllCameraZoom));
			mPCs.RemoveItem(PCOwner);
		}
	}
}

function ModifyAllCameraZoom()
{
	local GGMutatorComponent componentItr;
	local PlayerController tmpPC;
	local GGGoat goat;
	local bool cameraWasReset;
	//WorldInfo.Game.Broadcast(self, "ModifyAllCameraZoom");
	foreach mPCs(tmpPC)
	{
		goat=GGGoat(tmpPC.Pawn);
		if( goat == none || goat.DrawScale != 1.f || !IsZero(goat.Velocity))
			continue;

		foreach GGGameInfo(class'WorldInfo'.static.GetWorldInfo().Game).mMutatorComponents[ goat.mCachedSlotNr ].MutatorComponents( componentItr )
		{
			componentItr.ResetCameraZoom(tmpPC);
			componentItr.ModifyCameraZoom(goat);
			cameraWasReset=true;
		}
		if(!cameraWasReset)
		{
			DefaultResetCameraZoom(tmpPC);
		}
	}
	mPCs.Length=0;
}

function DefaultResetCameraZoom(Controller C)
{
	local GGCameraModeOrbital orbitalCamera;

	orbitalCamera = GGCameraModeOrbital( GGCamera( PlayerController( C ).PlayerCamera ).mCameraModes[ CM_ORBIT ] );

	orbitalCamera.mMaxZoomDistance = orbitalCamera.default.mMaxZoomDistance;
	orbitalCamera.mMinZoomDistance = orbitalCamera.default.mMinZoomDistance;
	orbitalCamera.mDesiredZoomDistance = orbitalCamera.default.mDesiredZoomDistance;
	orbitalCamera.mCurrentZoomDistance = orbitalCamera.default.mCurrentZoomDistance;
	orbitalCamera.mZoomUnit = orbitalCamera.default.mZoomUnit;
}

DefaultProperties
{
	mMutatorComponentClass=class'ResizableGoatComponent'
}