class ResizableGoatComponent extends GGMutatorComponent;

var GGGoat gMe;
var GGMutator myMut;
var bool isResizeEnabled;
var float mJumpMultiplier;
var bool mIsLickPressed;

var array<float> mSavedValues;

/**
 * See super.
 */
function AttachToPlayer( GGGoat goat, optional GGMutator owningMutator )
{
	super.AttachToPlayer(goat, owningMutator);

	if(mGoat != none)
	{
		gMe=goat;
		myMut=owningMutator;
	}
}

function UpdateComponent(float initScale, bool resizeEnabled)
{
	isResizeEnabled=(isResizeEnabled || resizeEnabled);
	if(initScale != 1.f)
	{
		ResizeMe(initScale);
	}
}

function KeyState( name newKey, EKeyState keyState, PlayerController PCOwner )
{
	local GGPlayerInputGame localInput;

	if(PCOwner != gMe.Controller || !isResizeEnabled)
		return;

	localInput = GGPlayerInputGame( PCOwner.PlayerInput );

	if( keyState == KS_Down )
	{
		//myMut.WorldInfo.Game.Broadcast(myMut, newKey);
		//XboxTypeS_RightShoulder
		//XboxTypeS_RightTrigger
		if( newKey == 'G' || newKey == 'XboxTypeS_DPad_Up')
		{
			ResizeMe(0.5f);
		}

		if( newKey == 'H' || newKey == 'XboxTypeS_DPad_Down')
		{
			ResizeMe(2.0f);
		}

		if(localInput.IsKeyIsPressed("GBA_AbilityBite", string( newKey )))
		{
			mIsLickPressed=true;
		}
	}
	else if( keyState == KS_Up )
	{
		if(localInput.IsKeyIsPressed("GBA_AbilityBite", string( newKey )))
		{
			mIsLickPressed=false;
		}
	}
}

/**
 * Resize your goat
 */
function ResizeMe(float multiplier)
{
	local float newScale, oldScale, oldJumpScale, newJumpScale, mNewCollisionRadius, mNewCollisionHeight, offset;
	local GGCameraModeOrbital orbitalCamera;
	local vector v;
	local bool goatWasRagdoll;
	local int diplayScale, i;

	local SkeletalMesh mOldMesh;
	local PhysicsAsset mOldPhysAsset;
	local AnimTree	 mOldAnimTree;
	local AnimSet		 mOldAnimSet;
	local MaterialInterface mOldMaterial;

	if(gMe.Controller == none)
		return;

	oldScale = gMe.DrawScale;
	newScale = oldScale * multiplier;

	if(myMut.WorldInfo.Game.GameSpeed >= 1.0f && !myMut.WorldInfo.bPlayersOnly && newScale < 1.0f/8.0f)
	{
		newScale = 1.0f/8.0f;
	}

	if(myMut.WorldInfo.Game.GameSpeed >= 1.0f && !myMut.WorldInfo.bPlayersOnly && newScale > 8.0f)
	{
		newScale = 8.0f;
	}

	oldJumpScale = mJumpMultiplier ** Loge(oldScale)/Loge(2);
	newJumpScale = mJumpMultiplier ** Loge(newScale)/Loge(2);

	goatWasRagdoll = gMe.mIsRagdoll;
	if(goatWasRagdoll)// Fix wrong mesh alignment if rescale heppen when ragdolled
	{
		gMe.CollisionComponent = gMe.Mesh;
		gMe.SetPhysics( PHYS_Falling );
		gMe.SetRagdoll( false );
	}

	if(oldScale != newScale)
	{
		//Display scale to the player
		if(newScale >= 1)
		{
			diplayScale=newScale;
			myMut.WorldInfo.Game.Broadcast(myMut, "x" $ diplayScale);
		}
		else
		{
			diplayScale=1.0/newScale;
			myMut.WorldInfo.Game.Broadcast(myMut, "x1/" $ diplayScale);
		}


		if(mIsLickPressed)//Easter egg (glitchy ragdoll scale)
		{
			//Change mesh scale
			gMe.SetDrawScale(newScale);
		}
		else
		{
			//FIX ragdoll scale !!!!!!!!!!!!!!!!
			mOldMesh = gMe.mesh.SkeletalMesh;
			mOldPhysAsset = gMe.mesh.PhysicsAsset;
			mOldAnimTree = gMe.mesh.AnimTreeTemplate;
			mOldAnimSet = gMe.mesh.AnimSets[ 0 ];
			mOldMaterial = gMe.mesh.GetMaterial( 0 );
			gMe.mesh.SetSkeletalMesh( none );
			gMe.mesh.SetPhysicsAsset( none );
			gMe.mesh.SetMaterial( 0, none );
			gMe.mesh.SetAnimTreeTemplate( none );// Need proper NPC anim tree for this to work.
			gMe.mesh.AnimSets[0] = none;

			//Change mesh scale
			gMe.SetDrawScale(newScale);

			gMe.mesh.SetSkeletalMesh( mOldMesh );
			gMe.mesh.SetPhysicsAsset( mOldPhysAsset );
			gMe.mesh.SetMaterial( 0, mOldMaterial );
			gMe.mesh.SetAnimTreeTemplate( mOldAnimTree );// Need proper NPC anim tree for this to work.
			gMe.mesh.AnimSets[0] = mOldAnimSet;
			//END fix ragdoll scale !!!!!!!!!!!!!!!!
			gMe.FetchTongueControl();
		}

		//Change collision box scale
		mNewCollisionRadius=gMe.GetCollisionRadius() * (1/oldScale) * newScale;
		mNewCollisionHeight=gMe.GetCollisionHeight() * (1/oldScale) * newScale;

		offset =  mNewCollisionHeight - gMe.GetCollisionHeight();
		gMe.SetCollisionSize( mNewCollisionRadius, mNewCollisionHeight );
		gMe.SetLocation( gMe.Location + vect( 0.0f, 0.0f, 1.0f ) * offset);

		//Change camera position and some other parameters
		v.x = 0.0f;
		v.y = mNewCollisionRadius;
		v.z = mNewCollisionHeight;
		gMe.mCameraLookAtOffset = v;

		orbitalCamera = GGCameraModeOrbital(GGCamera( PlayerController( gMe.Controller ).PlayerCamera ).mCameraModes[ CM_ORBIT ]);
		if(orbitalCamera != none)
		{
			orbitalCamera.mMaxZoomDistance = orbitalCamera.mMaxZoomDistance * (1/oldScale) * newScale;
			orbitalCamera.mMinZoomDistance = orbitalCamera.mMinZoomDistance * (1/oldScale) * newScale;
			orbitalCamera.mDesiredZoomDistance = orbitalCamera.mDesiredZoomDistance * (1/oldScale) * newScale;
			orbitalCamera.mCurrentZoomDistance = orbitalCamera.mCurrentZoomDistance * (1/oldScale) * newScale;
			orbitalCamera.mZoomUnit = orbitalCamera.mZoomUnit * (1/oldScale) * newScale;
		}

		//Change abilities range
		for(i=0 ; i<gMe.mAbilities.Length ; i++)
		{
			gMe.mAbilities[i].mRange = gMe.mAbilities[i].mRange * (1/oldScale) * newScale;
		}

		//If the scale is bigger than x1, change the goat speed
		if((multiplier > 1 && newScale > 1.0f) || (multiplier < 1 && newScale >= 1.0f))
		{
			if(oldScale < 1.f)// Just in case
				oldScale=1.f;

			gMe.mWalkSpeed = gMe.mWalkSpeed * (1/oldScale) * newScale;
			gMe.mStrafeSpeed = gMe.mStrafeSpeed * (1/oldScale) * newScale;
			gMe.mReverseSpeed = gMe.mReverseSpeed * (1/oldScale) * newScale;
			gMe.mSprintSpeed = gMe.mSprintSpeed * (1/oldScale) * newScale;
			gMe.GroundSpeed = gMe.GroundSpeed * (1/oldScale) * newScale;
			gMe.mWalkAccelRate = gMe.mWalkAccelRate * (1/oldScale) * newScale;
			gMe.mReverseAccelRate = gMe.mReverseAccelRate * (1/oldScale) * newScale;
			gMe.mSprintAccelRate = gMe.mSprintAccelRate * (1/oldScale) * newScale;
			gMe.AccelRate = gMe.AccelRate * (1/oldScale) * newScale;
			gMe.AirSpeed = gMe.AirSpeed * (1/oldScale) * newScale;
			gMe.mDecelerateInterpSpeed = gMe.mDecelerateInterpSpeed * (1/oldScale) * newScale;
			gMe.mWaterAccelRate = gMe.mWaterAccelRate * (1/oldScale) * newScale;
			gMe.mMaxSpeed = gMe.mSprintSpeed * 2.0f;
			gMe.CalcDesiredGroundSpeed();
			gMe.JumpZ = gMe.JumpZ * (1/oldJumpScale) * newJumpScale;

			gMe.mMinWallRunZ = gMe.mMinWallRunZ * (1/oldScale) * newScale;
			gMe.mWallRunZ = gMe.mWallRunZ * (1/oldScale) * newScale;
			gMe.mWallRunBoostZ = gMe.mWallRunBoostZ * (1/oldScale) * newScale;
			gMe.mWallRunSpeed = gMe.mWallRunSpeed * (1/oldScale) * newScale;
			gMe.mWallJumpZ = gMe.mWallJumpZ * (1/oldJumpScale) * newJumpScale;

			gMe.mRagdollLandSpeed = gMe.mRagdollLandSpeed * (1/oldScale) * newScale;
			gMe.mRagdollCollisionSpeed = gMe.mWalkSpeed + ( gMe.mSprintSpeed - gMe.mWalkSpeed ) * 0.5f;
			gMe.mRagdollJumpZ = gMe.mRagdollJumpZ * (1/oldJumpScale) * newJumpScale;

			gMe.mSpiderRunOffLedgeSpeed = gMe.mWalkSpeed + ( gMe.mSprintSpeed - gMe.mWalkSpeed ) * 0.1f;
		}
	}

	if(goatWasRagdoll)
	{
		gMe.SetRagdoll( true );
	}
}

function SaveCameraValues(Controller C)
{
	local GGCameraModeOrbital orbitalCamera;

	mSavedValues.Length=0;
	orbitalCamera = GGCameraModeOrbital(GGCamera( PlayerController( C ).PlayerCamera ).mCameraModes[ CM_ORBIT ]);
	if(orbitalCamera != none)
	{
		mSavedValues.AddItem(orbitalCamera.mMaxZoomDistance);
		mSavedValues.AddItem(orbitalCamera.mMinZoomDistance);
		mSavedValues.AddItem(orbitalCamera.mDesiredZoomDistance);
		mSavedValues.AddItem(orbitalCamera.mCurrentZoomDistance);
		mSavedValues.AddItem(orbitalCamera.mZoomUnit);
	}
}

function LoadCameraValues(Controller C)
{
	local GGCameraModeOrbital orbitalCamera;
	local int index;

	if(mSavedValues.Length == 0)
		return;

	orbitalCamera = GGCameraModeOrbital(GGCamera( PlayerController( C ).PlayerCamera ).mCameraModes[ CM_ORBIT ]);
	if(orbitalCamera != none)
	{
		orbitalCamera.mMaxZoomDistance = mSavedValues[index++];
		orbitalCamera.mMinZoomDistance = mSavedValues[index++];
		orbitalCamera.mDesiredZoomDistance = mSavedValues[index++];
		orbitalCamera.mCurrentZoomDistance = mSavedValues[index++];
		orbitalCamera.mZoomUnit = mSavedValues[index++];
	}
	mSavedValues.Length=0;
}

function ModifyCameraZoom( GGGoat goat )
{
	super.ModifyCameraZoom(goat);

	LoadCameraValues(goat.Controller);
}

function ResetCameraZoom( Controller C )
{
	SaveCameraValues(C);

	super.ResetCameraZoom(C);
}

defaultproperties
{
	mJumpMultiplier=1.4142135f // sqrt(2)
	//1.259921f // CubeSquare(2)
}