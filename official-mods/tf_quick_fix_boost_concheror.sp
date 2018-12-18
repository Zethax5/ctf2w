#pragma semicolon 1
#include <sourcemod>

#include <tf2_stocks>
#include <sdktools>
#include <sdkhooks>

#pragma newdecls required

#include <stocksoup/log_server>
#include <weaponmod_utils>

#define TF_ECON_DEFINDEX_QUICK_FIX 411

Handle g_SDKCallGetConditionProvider;

int g_iCritProvider[MAXPLAYERS + 1];

public void OnPluginStart() {
	Handle hGameConf = LoadGameConfigFile("tf2.weapon_overhaul");
	
	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature,
			"CTFPlayerShared::GetConditionProvider()");
	PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	g_SDKCallGetConditionProvider = EndPrepSDKCall();
	
	delete hGameConf;
}

public void TF2_OnConditionAdded(int client, TFCond cond) {
	if (cond != TFCond_MegaHeal) {
		return;
	}
	
	int provider = GetConditionProvider(client, cond);
	if (provider < 1 || provider > MaxClients) {
		return;
	}
	
	// verify that the condition is through the player's medigun
	int hMedigun = GetPlayerWeaponSlot(provider, 1);
	if (TF2_GetEntDefIndex(hMedigun) != TF_ECON_DEFINDEX_QUICK_FIX
			|| !GetEntProp(hMedigun, Prop_Send, "m_bChargeRelease")) {
		return;
	}
	
	TF2_AddCondition(client, TFCond_RegenBuffed, .inflictor = provider);
	TF2_AddCondition(client, TFCond_SpeedBuffAlly, .inflictor = provider);
	SDKHook(client, SDKHook_PostThinkPost, OnCritBoostPostThinkPost);
}

public void OnCritBoostPostThinkPost(int client) {
	if (TF2_IsPlayerInCondition(client, TFCond_MegaHeal)) {	
		g_iCritProvider[client] = GetConditionProvider(client, TFCond_MegaHeal);
		return;
	}
	
	if (g_iCritProvider[client] == GetConditionProvider(client, TFCond_RegenBuffed)) {
		TF2_RemoveCondition(client, TFCond_RegenBuffed);
	}
	if (g_iCritProvider[client] == GetConditionProvider(client, TFCond_SpeedBuffAlly)) {
		TF2_RemoveCondition(client, TFCond_SpeedBuffAlly);
	}
	g_iCritProvider[client] = -1;
}

// returns client providing condition
int GetConditionProvider(int client, TFCond cond) {
	Address pClientShared = GetEntityAddress(client)
			+ view_as<Address>(FindSendPropInfo("CTFPlayer", "m_Shared"));
	return SDKCall(g_SDKCallGetConditionProvider, pClientShared, cond);
}
