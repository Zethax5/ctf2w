#pragma semicolon 1
#include <sourcemod>

#include <dhooks>
#include <sdkhooks>
#include <tf2attributes>

#pragma newdecls required

#include <assembly_patch>
#include <weaponmod_utils>
#include <stocksoup/log_server>

#include <stocksoup/tf/tempents_stocks>

#define TF_ECON_DEFINDEX_HUO_LONG_HEATER 811

bool g_bHuoLongRageDraining[MAXPLAYERS + 1];

Handle g_DHookMinigunActivatePushbackAttack;
Handle g_SDKCallModifyRage, g_SDKCallActivatePushBackAttackMode;

Address g_pApplyOnHitAttributeHeavyRagePatch;
ArrayList g_UnpatchApplyOnHitAttributeHeavyRage;

Address g_pApplyPushFromDamageHeavyRagePatch;
ArrayList g_UnpatchApplyPushFromDamageHeavyRage;

Address g_pApplyHandleRageGainPatch;
ArrayList g_UnpatchHandleRageGain;

public void OnPluginStart() {
	Handle hGameConf = LoadGameConfigFile("tf2.weapon_overhaul");
	
	g_DHookMinigunActivatePushbackAttack = DHookCreateFromConf(hGameConf,
			"CTFMinigun::ActivatePushBackAttackMode()");
	DHookEnableDetour(g_DHookMinigunActivatePushbackAttack, false, OnMinigunActivatePushback);
	
	g_pApplyOnHitAttributeHeavyRagePatch = GameConfGetAddress(hGameConf,
			"CTFWeaponBase::ApplyOnHitAttributes_PatchHeavyRageStun");
	
	g_pApplyPushFromDamageHeavyRagePatch = GameConfGetAddress(hGameConf,
			"CTFPlayer::ApplyPushFromDamage_PatchHeavyRageStun");
	
	g_pApplyHandleRageGainPatch = GameConfGetAddress(hGameConf,
			"HandleRageGain_PatchHeavyRageDamage");
	
	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "CTFPlayerShared::ModifyRage()");
	PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
	g_SDKCallModifyRage = EndPrepSDKCall();
	
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature,
			"CTFMinigun::ActivatePushBackAttackMode()");
	g_SDKCallActivatePushBackAttackMode = EndPrepSDKCall();
	
	delete hGameConf;
	
	AssemblyData patchData = LoadAssemblyDataFile("tf2.weapon_overhaul");
	
	// check and patch OnSpyTouhedByEnemy
	ArrayList validateOnHitAttributeHeavyRage = AssemblyDataGetVerifyPayload(patchData,
			"CTFWeaponBase::ApplyOnHitAttributes_PatchHeavyRageStun");
	if (ValidateMemory(g_pApplyOnHitAttributeHeavyRagePatch, validateOnHitAttributeHeavyRage)) {
		ArrayList patch = AssemblyDataGetPatch(patchData,
				"CTFWeaponBase::ApplyOnHitAttributes_PatchHeavyRageStun");
		
		g_UnpatchApplyOnHitAttributeHeavyRage =
				AssemblyDataPerformPatch(g_pApplyOnHitAttributeHeavyRagePatch, patch);
		delete patch;
		
		LogServer("Successfully patched CTFWeaponBase::ApplyOnHitAttributes()");
	}
	delete validateOnHitAttributeHeavyRage;
	
	ArrayList validatePushFromDamageHeavyRage = AssemblyDataGetVerifyPayload(patchData,
			"CTFPlayer::ApplyPushFromDamage_PatchHeavyRageStun");
	if (ValidateMemory(g_pApplyPushFromDamageHeavyRagePatch, validatePushFromDamageHeavyRage)) {
		ArrayList patch = AssemblyDataGetPatch(patchData,
				"CTFPlayer::ApplyPushFromDamage_PatchHeavyRageStun");
		
		g_UnpatchApplyPushFromDamageHeavyRage =
				AssemblyDataPerformPatch(g_pApplyPushFromDamageHeavyRagePatch, patch);
		delete patch;
		
		LogServer("Successfully patched CTFPlayer::ApplyPushFromDamage()");
	}
	delete validatePushFromDamageHeavyRage;
	
	// HandleRageGain_PatchHeavyRageDamage
	ArrayList validateHandleRageGain = AssemblyDataGetVerifyPayload(patchData,
			"HandleRageGain_PatchHeavyRageDamage");
	if (ValidateMemory(g_pApplyHandleRageGainPatch, validateHandleRageGain)) {
		ArrayList patch = AssemblyDataGetPatch(patchData,
				"HandleRageGain_PatchHeavyRageDamage");
		
		g_UnpatchHandleRageGain =
				AssemblyDataPerformPatch(g_pApplyHandleRageGainPatch, patch);
		delete patch;
		
		LogServer("Successfully patched HandleRageGain()");
	}
	delete validateHandleRageGain;
	
	delete patchData;
	
	HookEvent("player_death", OnPlayerDeath);
}

public void OnPluginEnd() {
	if (g_UnpatchApplyOnHitAttributeHeavyRage) {
		AssemblyDataPerformPatch(g_pApplyOnHitAttributeHeavyRagePatch,
				g_UnpatchApplyOnHitAttributeHeavyRage);
		delete g_UnpatchApplyOnHitAttributeHeavyRage;
	}
	if (g_UnpatchApplyPushFromDamageHeavyRage) {
		AssemblyDataPerformPatch(g_pApplyPushFromDamageHeavyRagePatch,
				g_UnpatchApplyPushFromDamageHeavyRage);
		delete g_UnpatchApplyPushFromDamageHeavyRage;
	}
	if (g_UnpatchHandleRageGain) {
		AssemblyDataPerformPatch(g_pApplyHandleRageGainPatch, g_UnpatchHandleRageGain);
		delete g_UnpatchHandleRageGain;
	}
}

public void OnPlayerDeath(Event event, const char[] name, bool dontBroadcast) {
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	int assister = GetClientOfUserId(event.GetInt("assister"));
	
	if (attacker > 0 && attacker <= MaxClients
			&& TF2_GetEntDefIndex(GetPlayerWeaponSlot(attacker, 0))
			== TF_ECON_DEFINDEX_HUO_LONG_HEATER) {
		ModifyRage(attacker, 100.0 / 5.0);
	}
	
	if (assister > 0 && assister <= MaxClients
			&& TF2_GetEntDefIndex(GetPlayerWeaponSlot(assister, 0))
			== TF_ECON_DEFINDEX_HUO_LONG_HEATER) {
		ModifyRage(assister, 100.0 / 10.0);
	}
}


public void OnMapStart() {
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i)) {
			OnClientPutInServer(i);
		}
	}
}

public void OnClientPutInServer(int client) {
	SDKHook(client, SDKHook_PostThinkPost, OnClientPostThinkPost);
	SDKHook(client, SDKHook_OnTakeDamageAlivePost, OnTakeDamageAlivePost);
}

public void OnTakeDamageAlivePost(int victim, int attacker, int inflictor, float damage,
		int damagetype, int weapon, const float damageForce[3], const float damagePosition[3],
		int damagecustom) {
	if (TF2_GetEntDefIndex(weapon) != TF_ECON_DEFINDEX_HUO_LONG_HEATER) {
		return;
	}
	
	if (!g_bHuoLongRageDraining[attacker]) {
		return;
	}
	
	if (damagetype & DMG_BURN) {
		return;
	}
	
	TF2_IgnitePlayerEx(victim, attacker, weapon, 10.0);
}

public MRESReturn OnMinigunActivatePushback(int minigun) {
	if (TF2_GetEntDefIndex(minigun) != TF_ECON_DEFINDEX_HUO_LONG_HEATER) {
		return MRES_Ignored;
	}
	
	int owner = GetEntPropEnt(minigun, Prop_Send, "m_hOwnerEntity");
	if (!IsValidEntity(owner)) {
		return MRES_Ignored;
	}
	
	if (GetEntProp(owner, Prop_Send, "m_bRageDraining")) {
		return MRES_Supercede;
	}
	
	if (GetEntPropFloat(owner, Prop_Send, "m_flRageMeter") > 0.0) {
		SetEntProp(owner, Prop_Send, "m_bRageDraining", true);
		CreateTimer(0.5, ApplyHuoLongParticles, GetClientSerial(owner),
				TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	}
	
	return MRES_Supercede;
}

public Action ApplyHuoLongParticles(Handle timer, int clientserial) {
	int client = GetClientFromSerial(clientserial);
	if (!client || TF2_GetEntDefIndex(GetPlayerWeaponSlot(client, 0))
			!= TF_ECON_DEFINDEX_HUO_LONG_HEATER
			|| !GetEntProp(client, Prop_Send, "m_bRageDraining")) {
		return Plugin_Stop;
	}
	
	TE_SetupTFParticleEffect("water_burning_steam", NULL_VECTOR, .entity = client,
			.attachType = PATTACH_ABSORIGIN, .bResetParticles = false);
	TE_SendToAll();
	return Plugin_Continue;
}

public void OnClientPostThinkPost(int client) {
	int hActiveWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if (TF2_GetEntDefIndex(hActiveWeapon) != TF_ECON_DEFINDEX_HUO_LONG_HEATER) {
		return;
	}
	
	if (GetClientButtons(client) & IN_RELOAD) {
		ActivatePushBackAttackMode(hActiveWeapon);
	}
	
	bool bRageDraining = !!GetEntProp(client, Prop_Send, "m_bRageDraining");
	
	if (bRageDraining == g_bHuoLongRageDraining[client]) {
		// no state update
		return;
	}
	g_bHuoLongRageDraining[client] = bRageDraining;
	
	int hPrimary = GetPlayerWeaponSlot(client, 0);
	if (!IsValidEntity(hPrimary)) {
		return;
	}
	
	if (bRageDraining) {
		// inciden
		TF2Attrib_SetByName(hPrimary, "uses ammo while aiming", 9.0);
		TF2Attrib_SetByName(hPrimary, "projectile penetration heavy", 99.0);
		LogServer("heater in heat");
	} else {
		TF2Attrib_SetByName(hPrimary, "uses ammo while aiming", 3.0);
		TF2Attrib_RemoveByName(hPrimary, "projectile penetration heavy");
		LogServer("heater no heat");
	}
}

// we're using this since TF2_IgnitePlayer doesn't support burn durations
// calls CTFPlayerShared::Burn(CTFPlayer*, CTFWeaponBase*, float)
stock void TF2_IgnitePlayerEx(int client, int attacker = -1, int inflictor = -1, float flTime = 10.0) {
	static Handle s_SDKCall;
	
	if (!s_SDKCall) {
		Handle hGameConf = LoadGameConfigFile("sm-tf2.games");
		
		if (hGameConf) {
			StartPrepSDKCall(SDKCall_Raw);
			
			PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "Burn");
			
			PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Plain);
			PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Plain, VDECODE_FLAG_ALLOWNULL);
			PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
			
			s_SDKCall = EndPrepSDKCall();
			delete hGameConf;
		}
		
		if (!s_SDKCall) {
			ThrowError("Could not init call to CTFPlayerShared::Burn (TF2 extension gamedata)");
		}
	}
	
	if (attacker == -1) {
		attacker = client;
	}
	
	Address pShared = GetEntityAddress(client)
			+ view_as<Address>(FindSendPropInfo("CTFPlayer", "m_Shared"));
	SDKCall(s_SDKCall, pShared, attacker, inflictor, flTime);
}

bool ValidateMemory(Address addr, ArrayList validate) {
	if (validate.Length == 0) {
		LogError("failed to validate patch (zero length bytearray)");
		return false;
	}
	
	bool success = true;
	for (int i = 0; i < validate.Length; i++) {
		int membyte = LoadFromAddress(addr + view_as<Address>(i),
				NumberType_Int8);
		if (membyte != validate.Get(i)) {
			success = false;
			LogError("failed to validate patch (expected %2x, got %2x)", validate.Get(i),
					membyte);
		}
	}
	return success;
}

void ModifyRage(int client, float flRageGain) {
	if (GetEntProp(client, Prop_Send, "m_bRageDraining")) {
		float flRageMeter = GetEntPropFloat(client, Prop_Send, "m_flRageMeter") + flRageGain;
		
		if (flRageMeter > 100.0) {
			flRageMeter = 100.0;
		}
		
		SetEntPropFloat(client, Prop_Send, "m_flRageMeter", flRageMeter);
	} else {
		Address pShared = GetEntityAddress(client)
				+ view_as<Address>(FindSendPropInfo("CTFPlayer", "m_Shared"));
		SDKCall(g_SDKCallModifyRage, pShared, flRageGain);
	}
}

void ActivatePushBackAttackMode(int minigun) {
	SDKCall(g_SDKCallActivatePushBackAttackMode, minigun);
}
