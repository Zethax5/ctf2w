#pragma semicolon 1
#include <sourcemod>

#include <sdkhooks>
#include <tf2_stocks>

#pragma newdecls required

#include <stocksoup/tf/econ>

#define TF_ECON_DEFINDEX_MARKET_GARDENER 416
#define TF_ECON_DEFINDEX_ULLAPOOL_CABER 307

public void OnMapStart() {
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i)) {
			HookWeaponSwitch(i);
		}
	}
}

public void OnClientPutInServer(int client) {
	HookWeaponSwitch(client);
	HookPostThink(client);
}

void HookWeaponSwitch(int client) {
	SDKHook(client, SDKHook_WeaponSwitchPost, OnWeaponSwitchPost);
}

void HookPostThink(int client) {
	SDKHook(client, SDKHook_PostThinkPost, OnClientPostThinkPost);
}

public void OnWeaponSwitchPost(int client, int weapon) {
	if (TF2_IsPlayerInCondition(client, TFCond_BlastJumping)) {
		if (IsBlastJumpCritWeapon(weapon)) {
			TF2_AddCondition(client, TFCond_CritOnDamage);
		} else {
			TF2_RemoveCondition(client, TFCond_CritOnDamage);
		}
	}
}

public void TF2_OnConditionAdded(int client, TFCond cond) {
	if (cond == TFCond_BlastJumping) {
		int hActiveWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if (IsBlastJumpCritWeapon(hActiveWeapon)) {
			TF2_AddCondition(client, TFCond_CritOnDamage);
		} else {
			TF2_RemoveCondition(client, TFCond_CritOnDamage);
		}
	}
}

public void TF2_OnConditionRemoved(int client, TFCond cond) {
	if (cond == TFCond_BlastJumping) {
		if (IsBlastJumpCritWeapon(GetPlayerWeaponSlot(client, 2))) {
			TF2_RemoveCondition(client, TFCond_CritOnDamage);
		}
	}
}

public void OnClientPostThinkPost(client)
{
	if(IsBlastJumpCritWeapon(GetPlayerWeaponSlot(client, 2))
		&& GetClientFlags(client) & FL_ONGROUND == FL_ONGROUND) {
		
		TF2_RemoveCondition(client, TFCond_CritOnDamage);
	}
}

bool IsBlastJumpCritWeapon(int weapon) {
	if (!IsValidEntity(weapon)) {
		return false;
	}
	
	int defindex = TF2_GetItemDefinitionIndex(weapon);
	return (defindex == TF_ECON_DEFINDEX_MARKET_GARDENER
			|| defindex == TF_ECON_DEFINDEX_ULLAPOOL_CABER);
}
