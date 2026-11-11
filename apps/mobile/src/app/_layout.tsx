import { Stack } from 'expo-router';
import { StatusBar } from 'expo-status-bar';

export default function RootLayout() {
  return (
    <>
      <StatusBar style="auto" />
      <Stack>
        <Stack.Screen name="index" options={{ title: 'Family App' }} />
        <Stack.Screen name="adult" options={{ title: 'Family App — Parent' }} />
        <Stack.Screen name="child" options={{ title: 'Family App — Child' }} />
      </Stack>
    </>
  );
}
