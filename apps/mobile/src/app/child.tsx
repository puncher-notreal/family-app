import { StyleSheet, Text, View } from 'react-native';

// C-01 Day feed placeholder — real child UI is gated by TBD-CHILD-UI; pairing flow comes in Phase 2.
export default function ChildScreen() {
  return (
    <View style={styles.container}>
      <Text style={styles.text}>Child feed — placeholder (C-01)</Text>
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
