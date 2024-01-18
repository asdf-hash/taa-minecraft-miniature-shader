{
#ifdef HAND_DYNAMIC_LIGHTING

float strength = float(max(heldBlockLightValue, heldBlockLightValue2));
strength = max(torchStrength, min(1.0, strength / pow(length(worldPos) + 1.5, 2.0)));

#else

float strength = torchStrength;

#endif

torchColor = TORCH_COLOR * max(0.0, strength - 0.5*length(ambient.rgb));
}