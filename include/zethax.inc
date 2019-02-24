
//Damage stuff I totally didn't steal from Orion (sidenote: I did)
#define HL_DMG_GENERIC                      0                                                       // 0
#define TF_DMG_CRUSH                        (1 << 0)                                                // 1
#define TF_DMG_BULLET                       (1 << 1)                                                // 2            ► Bullet in general && Sniper Rifle ( Exception: The Classic ) && Scout's Homerun && Heavy's Showdown.
#define TF_DMG_BLEED                        (1 << 2)                                                // 4            ► Bleed in general && Cleaver && Spy's Fencing final damage.
#define TF_DMG_BURN                         (1 << 3)                                                // 8
#define SDK_DMG_UNUSED                      (1 << 4)                                                // 16
#define TF_DMG_FALL                         (1 << 5)                                                // 32           ► Fall in general && Mantreads's stomp.
#define TF_DMG_BLAST                        (1 << 6)                                                // 64           ► Also Engineer's Organ Grinder final damage.
#define TF_DMG_MISC                         (1 << 7)                                                // 128          ► Sandman's ball && Wrap Assassin's ball && Shield && Demoman's Decapitation Taunt Kill && Engineer's Dischord && Headless Horseless Horsemann.
#define SDK_DMG_UNUSED2                     (1 << 8)                                                // 256
#define SDK_DMG_UNUSED3                     (1 << 9)                                                // 512
#define DOTA_DMG_DISPERSION                 (1 << 10)                                               // 1024
#define TF_PREVENT_PHYSICS_FORCE            (1 << 11)                                               // 2048
#define TF_DMG_SOMETAUNTKILLS               TF_PREVENT_PHYSICS_FORCE | TF_DMG_BULLET                // 2050         ► Engineer's Organ Grinder spinning phase && Medic's Spinal Tap initial AND final damage && Sniper's Skewer.
#define TF_DMG_SPY_FENCING                  TF_PREVENT_PHYSICS_FORCE | TF_DMG_BLEED                 // 2052         ► Only the first 2 damages instances.
#define TF_DMG_AFTERBURN                    TF_PREVENT_PHYSICS_FORCE | TF_DMG_BURN                  // 2056
#define TF_DMG_BLAST_WRAPASSASSIN           TF_PREVENT_PHYSICS_FORCE | TF_DMG_BLAST                 // 2112
#define TF_DMG_ZATOICHI_RETURN				TF_PREVENT_PHYSICS_FORCE | TF_DMG_MISC			     	// 2176
#define TF_NEVERGIB                     	(1 << 12)                                               // 4096
#define TF_ALWAYSGIB                    	(1 << 13)                                               // 8192
#define TF_DMG_DROWN                        (1 << 14)                                               // 16384
#define DOTA_DMG_OTHER                      (1 << 15)                                               // 32768
#define TF_DMG_ENV                          (1 << 16)                                               // 65536
#define TF_PLUS1                    		(1 << 17)                                               // 131072
#define TF_DMG_LASER						TF_PLUS1 | TF_DMG_BULLET								// 131074
#define TF_PLUS2                   	 		(1 << 18)                                               // 262144
#define TF_DMG_GRENADE                      TF_PLUS2 | TF_DMG_BLAST                         		// 262208
#define TF_DMG_DROWNRECOVER                 (1 << 19)                                               // 524288
#define TF_DMG_CRIT                         (1 << 20)                                               // 1048576      ► Also Mini-Crit.
#define TF_DMG_GRENADE_CRIT                 TF_DMG_GRENADE | TF_DMG_CRIT                            // 1310784      ► Also Double Donk.
#define TF_PLUS3                    		(1 << 21)                                               // 2097152
#define TF_DMG_BULLET2                      TF_PLUS3 | TF_DMG_BULLET                        		// 2097154      ► Pistol && Minigun && Short Circuit && SMG.
#define TF_DMG_SOLDIER_KAMIKAZE             TF_PLUS3 | TF_DMG_BLAST                         		// 2097216      ► Also the Caber's explosion.
#define TF_DMG_BISON						TF_PLUS3 | TF_DMG_LASER									// 2228226		► Righteous Bison & Pomson.
#define TF_DMG_SYRINGE                      TF_PLUS3 | TF_PLUS1 | TF_PREVENT_PHYSICS_FORCE | TF_DMG_BULLET    // 2230274
#define TF_DMG_SENTRY                       TF_PLUS3 | TF_PLUS1 | TF_NEVERGIB | TF_DMG_BULLET       // 2232322
#define TF_DMG_ROCKET                       TF_PLUS3 | TF_DMG_GRENADE                       		// 2359360      ► Also Sentry's Rocket.
#define TF_DMG_STICKY                       TF_PLUS3 | TF_PLUS1 | TF_DMG_GRENADE    				// 2490432
#define TF_DMG_BULLET2_CRIT                 TF_DMG_BULLET2 | TF_DMG_CRIT                            // 3145730      ► Pistol && Minigun && Short Circuit && SMG.
#define TF_DMG_ROCKET_CRIT                  TF_DMG_ROCKET | TF_DMG_CRIT                             // 3407936
#define TF_DMG_STICKY_CRIT                  TF_DMG_STICKY | TF_DMG_CRIT                             // 3539008
#define TF_DMG_REMOVENORAGDOLL              (1 << 22)                                               // 4194304
#define SDK_DMG_UNUSED4                    	(1 << 23)                                              	// 8388608
#define TF_DMG_FIRE                         (1 << 24)                                               // 16777216     ► Fire in general && Pyro's Armageddon && Huo-Long Heater's Ring of Fire.
#define TF_DMG_FLARE                        TF_DMG_FIRE | TF_DMG_BULLET                             // 16777218
#define TF_DMG_PYRO_HADOUKEN                TF_DMG_FIRE | TF_DMG_BURN                               // 16777224
#define TF_DMG_FLAMETHROWER                 TF_PREVENT_PHYSICS_FORCE | TF_DMG_FIRE             		// 16779264
#define TF_DMG_SCORCHSHOT                   TF_DMG_FLAMETHROWER | TF_DMG_BULLET                     // 16779266     ► Scorch Shot && Pyro's Execution.
#define TF_DMG_FLARE_CRIT                   TF_DMG_FLARE | TF_DMG_CRIT                              // 17825794
#define TF_DMG_FLAMETHROWER_CRIT            TF_DMG_FLAMETHROWER | TF_DMG_CRIT                       // 17827840
#define TF_DMG_BLAST_FLARE                  TF_DMG_FLARE | TF_PLUS2                         		// 17039362     ► Scorch Shot && Detonator explosion.
#define TF_DMG_BLAST_FLARE_CRIT             TF_DMG_FLARE_CRIT | TF_PLUS2                    		// 18087938     ► Scorch Shot && Detonator explosion.
#define TF_DMG_COWMANGLER_CHARGED			TF_DMG_FIRE | TF_DMG_ROCKET								// 19136576
#define TF_PLUS4                    		(1 << 25)                                               // 33554432
#define TF_DMG_RIFLE_CHARGED                TF_PLUS4 | TF_DMG_BULLET                        		// 33554434     ► Also Crusader's Crossbow && Huntsman && The Classic.
#define TF_DMG_RIFLE_CRIT                   TF_DMG_RIFLE_CHARGED | TF_DMG_CRIT                      // 34603010     ► Also Crusader's Crossbow && Huntsman && The Classic.
#define TF_DMG_AMBASSADOR                   TF_PLUS4 | TF_DMG_BULLET2                       		// 35651586
#define TF_DMG_AMBASSADOR_CRIT              TF_DMG_AMBASSADOR | TF_DMG_CRIT                         // 35651586     ► Only when able to Headshot.
#define SDK_DMG_UNUSER5                    	(1 << 26)                                               // 67108864
#define TF_DMG_BLAST_SURFACE                (1 << 27)                                               // 134217728
#define TF_DMG_MELEE                        TF_DMG_BLAST_SURFACE | TF_NEVERGIB | TF_DMG_MISC    	// 134221952
#define TF_DMG_MELEE_CRIT                   TF_DMG_MELEE | TF_DMG_CRIT                              // 135270528
#define DOTA_DMG_BLADEMAIL                  (1 << 28)                                               // 268435456
#define TF_PLUS5                    		(1 << 29)                                               // 536870912
#define TF_DMG_SCATTERGUN                   TF_PLUS5 | TF_PLUS3                     				// 538968064    ► Scattergun && Shotgun && Rescue Ranger.
#define TF_DMG_SHORTSTOP                    TF_DMG_SCATTERGUN | TF_DMG_BULLET                       // 538968066
#define TF_DMG_SCATTERGUN_CRIT              TF_DMG_SCATTERGUN | TF_DMG_CRIT                         // 540016640    ► Scattergun && Shotgun && Rescue Ranger.
#define TF_DMG_SHORTSTOP_CRIT               TF_DMG_SHORTSTOP | TF_DMG_CRIT                          // 540016642

new Float:CombatTime[MAXPLAYERS + 1];
new LastWeaponHurtWith[MAXPLAYERS + 1];

//Returns the medigun patient of the client
//@param client					Target client
stock GetMediGunPatient(client)
{
	new wep = GetPlayerWeaponSlot(client, 1);
	if (wep == -1 || wep != GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon")) return -1;
	new String:class[15];
	GetEdictClassname(wep, class, sizeof(class));
	if (StrContains(class, "tf_weapon_med", false)) return -1;
	return GetEntProp(wep, Prop_Send, "m_bHealing") ? GetEntPropEnt(wep, Prop_Send, "m_hHealingTarget") : -1;
}

//Returns the maximum health of a client
//@param client					Target client
stock GetClientMaxHealth(client)
{
	if(client == -1) return 0;
	return GetEntProp(client, Prop_Data, "m_iMaxHealth");
}

//Returns the client's active weapon
//@param client				The client you want to get the weapon of
stock GetActiveWeapon(client)
{
	if (!IsValidClient(client))return -1;
	if(GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon") > -1)
	{
		return GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	}
	else return -1;
}

//Returns the definition index of the client's weapon
//@param client				The target client
//@param weapon				The target weapon you wish to get the definition index of
stock GetWeaponIndex(weapon)
{
	if (weapon < 0 || weapon > 2049)return -1;
	return GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
}

/*
Spawns an entity on a certain team and teleports them to a designated postition
@param entity				Name of the entity
@param spawn				Spawn position of the entity
@param team 				The team to spawn it on.
		Some entities don't work with teams, such as the Skeleton King
*/
stock SpawnEntity(String:entity[32]="", spawn, team)
{
    new ent = CreateEntityByName(entity);
    if (IsValidEntity(ent))
    {
        DispatchSpawn(ent);
	
        if (StrEqual(entity, "tf_zombie_spawner")) {
            SetEntProp(ent, Prop_Data, "m_nSkeletonType", 1);
            AcceptEntityInput(ent, "Enable");
        }
        else if (StrEqual(entity, "tf_zombie")) {
            if (team == 2) DispatchKeyValue(ent, "skin", "0");
            else if (team == 3) DispatchKeyValue(ent, "skin", "1");
            SetEntProp(ent, Prop_Send, "m_iTeamNum", team);
        }
        else if (StrEqual(entity, "eyeball_boss")) SetEntProp(ent, Prop_Data, "m_iTeamNum", 5);

        new Float:POSi[3];
        GetClientAbsOrigin(victim, POSi);
        TeleportEntity(ent, POSi, NULL_VECTOR, NULL_VECTOR);
    }
}
//
////
//////
///////
// Ammo related stuff
///////
//////
////
//

//Gets the clip of a weapon and returns it
stock GetClip_Weapon(weapon)
{
	if (weapon == -1)return 0;
	new iAmmoTable = FindSendPropInfo("CTFWeaponBase", "m_iClip1");
	return GetEntData(weapon, iAmmoTable, 4);
}

//Gets the ammo of a weapon and returns it
stock GetAmmo_Weapon(weapon)
{
	if (weapon == -1) return 0;
	new owner = GetEntPropEnt(weapon, Prop_Send, "m_hOwnerEntity");
	if (owner == -1) return 0;
	return GetEntProp(owner, Prop_Data, "m_iAmmo", 4, 3);
}

//Sets the clip of a weapon
stock SetClip_Weapon(weapon, newClip)
{
	if (weapon == -1)return;
	new iAmmoTable = FindSendPropInfo("CTFWeaponBase", "m_iClip1");
	SetEntData(weapon, iAmmoTable, newClip, 4, true);
}

//Sets the ammo of a weapon.
stock SetAmmo_Weapon(weapon, newAmmo)
{
	new owner = GetEntPropEnt(weapon, Prop_Send, "m_hOwnerEntity");
	if (owner == -1) return;
	if (weapon == -1)return;
	SetEntProp(owner, Prop_Data, "m_iAmmo", newAmmo, 4, 3);
}
/*
Deals damage to a specific client through the use of "point_hurt" entities.
I basically stole this from Orion, who might have stolen it from smlib.
@param victim				The player the damage is being dealt to
@param damage				The amount of damage being dealt, using an integer value.
@param attacker				The player dealing the damage.
@param dmg_type				The type of damage being dealt. Defaults to DMG_GENERIC
@param logname				How it displays in the server log/player console
*/
stock DealDamage(victim, damage, attacker=0, dmg_type=HL_DMG_GENERIC ,String:logname[]="")
{
    if(victim>0 && IsValidEdict(victim) && IsClientInGame(victim) && IsPlayerAlive(victim) && damage>0)
    {
        new String:dmg_str[16];
        IntToString(damage,dmg_str,16);
        new String:dmg_type_str[32];
        IntToString(dmg_type,dmg_type_str,32);
        new pointHurt=CreateEntityByName("point_hurt");
        if(pointHurt)
        {
            DispatchKeyValue(victim,"targetname","war3_hurtme");
            DispatchKeyValue(pointHurt,"DamageTarget","war3_hurtme");
            DispatchKeyValue(pointHurt,"Damage",dmg_str);
            DispatchKeyValue(pointHurt,"DamageType",dmg_type_str);
            if(!StrEqual(logname,""))
            {
                DispatchKeyValue(pointHurt,"classname",logname);
            }
            DispatchSpawn(pointHurt);
            AcceptEntityInput(pointHurt,"Hurt",(attacker>0)?attacker:-1);
            DispatchKeyValue(pointHurt,"classname","point_hurt");
            DispatchKeyValue(victim,"targetname","war3_donthurtme");
            RemoveEdict(pointHurt);
        }
    }
}

/*
Induces a fake healing effect because Sourcemod does not come with that
@param healer				The client doing the healing
@param patient				The patient to recieve the healing
@param amount				The amount to heal patients by per impulse
@param overheal				Maximum amount of overheal your patients are allowed to have. 1.0 for no overheal
*/
stock HealPlayer(healer = -1, patient = -1, amount = 0, Float:overheal = 1.0)
{
	if (healer <= 0 || healer > MaxClients)return;
	if (patient <= 0 || patient > MaxClients)return;
	new health = GetClientHealth(patient);
	new maxhealth = GetClientMaxHealth(patient);
	if(amount > 0)
	{
		health += amount;
		SetEntityHealth(patient, health);
		new Handle:healevent = CreateEvent("player_healed", true);
		SetEventInt(healevent, "patient", patient);
		SetEventInt(healevent, "healer", healer);
		SetEventInt(healevent, "amount", amount);
		FireEvent(healevent);
		if(health > maxhealth * overheal)
		{
			health = maxhealth * overheal;
		}
	}
}

/*
Spawns a particle effect. Thanks to Orion for lending me the code for this.
@param client				The client creating the particle
@param particle				The name of the particle being spawned
*/
stock SpawnParticle(client, String:particleName[]="", Float:addPos[3] = NULL_VECTOR)
{
	if (client <= 0 || client > MaxClients)return;
	new particle = CreateEntityByName( "info_particle_system" );
	new Float:m_flPosition[3];
	GetClientAbsOrigin(client, m_flPosition);
	AddVectors(m_flPosition, addPos, m_flPosition);
	if ( IsValidEntity( particle ) )
	{
		TeleportEntity( particle, m_flPosition, NULL_VECTOR, NULL_VECTOR );
		DispatchKeyValue( particle, "effect_name", particleName );
		DispatchSpawn( particle );
		ActivateEntity( particle );
		AcceptEntityInput( particle, "start" );
		SetVariantString( "OnUser1 !self:Kill::8:-1" );
		AcceptEntityInput( particle, "AddOutput" );
		AcceptEntityInput( particle, "FireUser1" );
	}
}

/*
Applies healing or damage to players in a specific radius
@param client				The client defining the origin point of the explosion
@param inflictor			The client inflicting the explosion. Defaults to the client
@param exception			A client you don't want to be affected by the explosion, for whatever reason
@param radius				Radius for the explosion.
@param falloff 				Maximum damage falloff multiplier for the damage
@param amount				Amount of damage/healing to be dealt to qualifying players in the radius
@param dmgtype 				The type of damage being dealt, if damage is being dealt at all.
@param team					Which teams will be affected by this explosion. 0 = All teams, 1 = Same team, 2 = Opposing team
@param clientIsAffected		Determines whether or not the client is affected by the explosion.
*/
stock DealRadiusDamage(iClient, iAttacker=-1, iException=-1, Float:flRadius=0.0, Float:flFalloff=1.0, iAmount=0, iDmgType=0, iTeam=2, bool:bClientIsAffected=false)
{
	if (iClient <= 0 || iClient > MaxClients)return;
	for (new i = 1; i <= MaxClients; i++)
	{
		new Float:flPos1[3];
		GetClientAbsOrigin(iClient, flPos1); 
		
		if(IsValidClient(i) && IsClientInGame(i) && IsPlayerAlive(i))
		{ 
			if (!bClientIsAffected && i == iClient)continue;
			if (iException > 0 && i == iException)continue;
			if (iTeam == 1 && GetClientTeam(i) != GetClientTeam(iClient))continue;
			if (iTeam == 2 && GetClientTeam(i) == GetClientTeam(iClient))continue;
			
			new Float:flPos2[3];
			GetClientAbsOrigin(i, flPos2);
			new Float:flDistance = GetVectorDistance(flPos1, flPos2);
			if(flDistance <= flRadius)
			{
				new iInflictor;
				if (iAttacker > 0)iInflictor = iAttacker;
				else iInflictor = iClient;
				if(iAmount < 0)
				{
					SetEntityHealth(i, GetClientHealth(i) + iAmount);
					new Handle:healevent = CreateEvent("player_healonhit", true);
					SetEventInt(healevent, "entindex", iInflictor);
					SetEventInt(healevent, "amount", iAmount);
					FireEvent(healevent);
				}
				else if(iAmount > 0)
				{
					new damage;
					damage = RoundToFloor(iAmount * (1.0 - ((flDistance / flRadius) * flFalloff)));
					if (damage < RoundFloat(iAmount * flFalloff))damage = RoundFloat(iAmount * flFalloff);
					DealDamage(i, damage, iInflictor, iDmgType, "");
				}
			}
		}
	}
}

/*
Applies conditions to players in a radius.
@param client				The client defining the origin point of the explosion
@param inflictor			The client inflicting the explosion. Defaults to the client
@param exception			A client you don't want to be affected by the explosion, for whatever reason
@param radius				Radius for the explosion.
@param cond1				First condition to apply to qualifying players in the radius.
@param cond2				Second condition to apply to qualifying players in the radius.
@param dur1					Duration to apply condition 1 for.
@param dur2					Duration to apply condition 2 for.
@param team					Which teams will be affected by this explosion. 0 = All teams, 1 = Same team, 2 = Opposing team
@param clientIsAffected		Determines whether or not the client is affected by the explosion.
*/
stock ApplyRadiusEffects(iClient, iAttacker=-1, iException=-1, Float:flRadius=0.0, iCond1=-1, iCond2=-1, Float:flDur1=0.0, Float:flDur2=0.0, iTeam=0, bool:bClientIsAffected=false)
{
	if (iClient <= 0 || iClient > MaxClients)return;
	for (new i = 1; i <= MaxClients; i++)
	{
		new Float:flPos1[3];
		GetClientAbsOrigin(iClient, flPos1); 
		
		if(IsValidClient(i) && IsClientInGame(i) && IsPlayerAlive(i))
		{ 
			if (!bClientIsAffected && i == iClient)continue;
			if (iException > 0 && i == iException)continue;
			if (iTeam == 1 && GetClientTeam(i) != GetClientTeam(iClient))continue;
			if (iTeam == 2 && GetClientTeam(i) == GetClientTeam(iClient))continue;
			new Float:flPos2[3];
			GetClientAbsOrigin(i, flPos2);
			new Float:flDistance = GetVectorDistance(flPos1, flPos2);
			if(flDistance <= flRadius)
			{
				new iInflictor;
				if (iAttacker >= 1)iInflictor = iAttacker;
				else iInflictor = iClient;
				if(iCond1 > 0)
				{
					TF2_AddCondition(i, TFCond:iCond1, flDur1, iInflictor);
				}
				if(iCond2 > 0)
				{
					TF2_AddCondition(i, TFCond:iCond2, flDur2, iInflictor);
				}
			}
		}
	}
}

stock Action:ActionApply(Action:aPrevious, Action:aNew)
{
	if(aNew != Plugin_Continue) aPrevious = aNew;
	return aPrevious;
}


/*
Finds the given attribute in any slot and returns the slot the attribute was found in
@param client			The target client index
@param MinSlot			The first slot to check, defaults to the primary slot
@param MaxSlot			The last slot to check, defaults to the melee slot
@param Attribute		The attribute to check each slot for
*/
stock FindAttribute(client, MinSlot = 0, MaxSlot = 2, bool:Attribute[2049])
{
	new slot;
	for (new i = MinSlot; i >= MaxSlot; i++)
	{
		slot = GetPlayerWeaponSlot(client, i);
		if(slot < 0 || !Attribute[slot])
			continue;
		else
			return slot;
	}
	return -1;
}

/*
Finds and returns the given entity's owner
@param entity			The target entity
@return 				The target entity's owner
*/
stock ReturnOwner(entity)
{
	if (entity < 0 || entity > 2048)return -1;
	new owner = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
	if (owner < 0 || owner > 2048)return -1;
	return owner;
}

/*
Gets the classname of the given entity. Credit goes to Chawlz since I stole this from his code
@param entity			The entity
@param classname		The string to compare to
*/
stock bool:IsClassname(entity, String:strClassname[])
{
	if(entity < 0 || entity > 2048) return false;
	
	decl String:strClassname2[32];
	GetEdictClassname(entity, strClassname2, sizeof(strClassname2));
	if(!StrEqual(strClassname, strClassname2, false)) return false;
	
	return true;
}

stock bool:IsEntityBuilding(entity)
{
	if(entity <= 0) return false;
	if(!IsValidEdict(entity)) return false;
	if(IsClassname(entity, "obj_sentrygun")) return true;
	if(IsClassname(entity, "obj_dispenser")) return true;
	if(IsClassname(entity, "obj_teleporter")) return true;
	return false;
}

stock any:AttachParticle(ent, String:particleType[], Float:time = 0.0, Float:addPos[3]=NULL_VECTOR, Float:addAngle[3]=NULL_VECTOR, bool:bShow = true, String:strVariant[] = "", bool:bMaintain = false)
{
	new particle = CreateEntityByName("info_particle_system");
	if(IsValidEdict(particle))
	{
		new Float:pos[3];
		new Float:ang[3];
		decl String:tName[32];
		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);
		AddVectors(pos, addPos, pos);
		GetEntPropVector(ent, Prop_Send, "m_angRotation", ang);
		AddVectors(ang, addAngle, ang);

		Format(tName, sizeof(tName), "target%i", ent);
		DispatchKeyValue(ent, "targetname", tName);

		TeleportEntity(particle, pos, ang, NULL_VECTOR);
		DispatchKeyValue(particle, "targetname", "tf2particle");
		DispatchKeyValue(particle, "parentname", tName);
		DispatchKeyValue(particle, "effect_name", particleType);
		DispatchSpawn(particle);
		SetEntPropEnt(particle, Prop_Send, "m_hOwnerEntity", ent);
		if(bShow)
		{
			SetVariantString(tName);
		} else
		{
			SetVariantString("!activator");
		}
		AcceptEntityInput(particle, "SetParent", ent, particle, 0);
		if(!StrEqual(strVariant, ""))
		{
			SetVariantString(strVariant);
			if(bMaintain) AcceptEntityInput(particle, "SetParentAttachmentMaintainOffset", ent, particle, 0);
			else AcceptEntityInput(particle, "SetParentAttachment", ent, particle, 0);
		}
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
		if(time > 0.0) CreateTimer(time, RemoveParticle, particle);
	}
	else LogError("AttachParticle: could not create info_particle_system");
	return particle;
}

stock PrecacheParticle(String:strName[])
{
	if(IsValidEntity(0))
	{
		new particle = CreateEntityByName("info_particle_system");
		if(IsValidEdict(particle))
		{
			new String:tName[32];
			GetEntPropString(0, Prop_Data, "m_iName", tName, sizeof(tName));
			DispatchKeyValue(particle, "targetname", "tf2particle");
			DispatchKeyValue(particle, "parentname", tName);
			DispatchKeyValue(particle, "effect_name", strName);
			DispatchSpawn(particle);
			SetVariantString(tName);
			AcceptEntityInput(particle, "SetParent", 0, particle, 0);
			ActivateEntity(particle);
			AcceptEntityInput(particle, "start");
			CreateTimer(0.01, RemoveParticle, particle);
		}
	}
}

public Action:RemoveParticle(Handle:timer, any:particle) //Chawlz' code
{
	if(particle >= 0 && IsValidEntity(particle))
	{
		new String:classname[32];
		GetEdictClassname(particle, classname, sizeof(classname));
		if(StrEqual(classname, "info_particle_system", false))
		{
			AcceptEntityInput(particle, "Stop");
			AcceptEntityInput(particle, "Kill");
			AcceptEntityInput(particle, "Deactivate");
			particle = -1;
		}
	}
}
