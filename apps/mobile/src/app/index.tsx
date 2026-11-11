import { useState } from 'react';
import { Pressable, ScrollView, StyleSheet, Text, View } from 'react-native';
import { Link } from 'expo-router';
import { checkApiHealth } from '../lib/api';

export default function WelcomeScreen() {
  const [health, setHealth] = useState<string | null>(null);

  const onCheckApi = async () => {
    setHealth('checking…');
    try {
      const result = await checkApiHealth();
      setHealth(result);
    } catch {
      setHealth('API unreachable');
    }
  };

  return (
    <ScrollView contentContainerStyle={styles.container}>
      <Text style={styles.title}>Family App</Text>
      <Text style={styles.subtitle}>Family companion — kids 7–12, parents, RU/EN (skeleton v0.1)</Text>

      <Link href="/adult" asChild>
        <Pressable style={styles.button}>
          <Text style={styles.buttonText}>Я родитель / I am a parent</Text>
        </Pressable>
      </Link>

      <Link href="/child" asChild>
        <Pressable style={[styles.button, styles.buttonSecondary]}>
          <Text style={styles.buttonText}>Я ребёнок / I am a child</Text>
        </Pressable>
      </Link>

      <View style={styles.statusRow}>
        <Pressable onPress={onCheckApi} style={styles.checkButton}>
          <Text style={styles.checkButtonText}>Check API /health</Text>
        </Pressable>
        {health !== null && <Text style={styles.statusText}>{health}</Text>}
      </View>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    padding: 24,
    gap: 16,
  },
  title: {
    fontSize: 32,
    fontWeight: '700',
  },
  subtitle: {
    fontSize: 14,
    textAlign: 'center',
    opacity: 0.7,
    marginBottom: 16,
  },
  button: {
    backgroundColor: '#208AEF',
    paddingVertical: 14,
    paddingHorizontal: 32,
    borderRadius: 12,
    minWidth: 260,
    alignItems: 'center',
  },
  buttonSecondary: {
    backgroundColor: '#34A853',
  },
  buttonText: {
    color: '#FFFFFF',
    fontSize: 16,
    fontWeight: '600',
  },
  statusRow: {
    marginTop: 24,
    alignItems: 'center',
    gap: 8,
  },
  checkButton: {
    paddingVertical: 8,
    paddingHorizontal: 16,
    borderRadius: 8,
    borderWidth: 1,
    borderColor: '#208AEF',
  },
  checkButtonText: {
    color: '#208AEF',
    fontSize: 13,
  },
  statusText: {
    fontSize: 12,
    opacity: 0.8,
  },
});
