#pragma semicolon 1
#include <sourcemod>

#include <dhooks>
#include <sdktools>

#pragma newdecls required

#include <stocksoup/log_server>
#include <stocksoup/tf/econ>
#include <stocksoup/tf/player>

#include <weaponmod_utils>

#define TF_ECON_DEFINDEX_SHORTSTOP 220

#define SHORTSTOP_HEAL_MULT 1.5

Handle g_DHookPlayerTakeHealth;
Handle g_SDKPlayerIsCapturingPoint, g_SDKPlayerGetControlPoint;

float g_flShortstopHealFrac[MAXPLAYERS + 1];

public void OnPluginStart() {
	Handle hGameConf = LoadGameConfigFile("tf2.weapon_overhaul");
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "CTFPlayer::IsCapturingPoint()");
	PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
	g_SDKPlayerIsCapturingPoint = EndPrepSDKCall();
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature,
			"CTFPlayer::GetControlPointStandingOn()");
	PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
	g_SDKPlayerGetControlPoint = EndPrepSDKCall();
	
	int iOffset = GameConfGetOffset(hGameConf, "CTFPlayer::TakeHealth()");
	if (iOffset == -1) {
		SetFailState("Missing offset for CTFPlayer::TakeHealth()"); 
	}
	
	g_DHookPlayerTakeHealth = DHookCreate(iOffset, HookType_Entity, ReturnType_Bool,
			ThisPointer_CBaseEntity, OnPlayerTakeHealth);
	DHookAddParam(g_DHookPlayerTakeHealth, HookParamType_Float); // flHealth
	DHookAddParam(g_DHookPlayerTakeHealth, HookParamType_Int); // bitsDamageType
	
	delete hGameConf;
}

public void OnMapStart() {
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i)) {
			HookPlayerTakeHealth(i);
		}
	}
}

public void OnClientPutInServer(int client) {
	HookPlayerTakeHealth(client);
}

void HookPlayerTakeHealth(int client) {
	DHookEntity(g_DHookPlayerTakeHealth, false, client);
}

public MRESReturn OnPlayerTakeHealth(int client, Handle hReturn, Handle hParams) {
	int hActiveWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	
	float flHealth = DHookGetParam(hParams, 1);
	
	if (TF2_GetEntDefIndex(hActiveWeapon) != TF_ECON_DEFINDEX_SHORTSTOP) {
		return MRES_Ignored;
	}
	
	if (!IsDoingObjective(client)) {
		return MRES_Ignored;
	}
	
	g_flShortstopHealFrac[client] += flHealth * SHORTSTOP_HEAL_MULT;
	
	if (g_flShortstopHealFrac[client] > 1.0) {
		float flHealAmount = float(RoundToFloor(g_flShortstopHealFrac[client]));
		g_flShortstopHealFrac[client] -= flHealAmount;
		
		DHookSetParam(hParams, 1, flHealAmount);
	} else {
		DHookSetParam(hParams, 1, 0.0);
	}
	return MRES_ChangedHandled;
}

bool IsDoingObjective(int client) {
	return IsValidEntity(GetEntPropEnt(client, Prop_Send, "m_hItem"))
			|| IsCapturingPoint(client) || IsValidEntity(GetControlPointStandingOn(client));
}

bool IsCapturingPoint(int client) {
	return SDKCall(g_SDKPlayerIsCapturingPoint, client);
}

// returns a triugger_capture_area
int GetControlPointStandingOn(int client) {
	return SDKCall(g_SDKPlayerGetControlPoint, client);
}
