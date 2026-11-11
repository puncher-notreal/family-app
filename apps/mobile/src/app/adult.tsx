import { StyleSheet, Text, View } from 'react-native';

// P-01 Day feed placeholder — implemented in Phase 2+ (role routing, auth).
export default function AdultScreen() {
  return (
    <View style={styles.container}>
      <Text style={styles.text}>Adult feed — placeholder (P-01)</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    padding: 24,
  },
  text: {
    fontSize: 16,
    textAlign: 'center',
  },
});
