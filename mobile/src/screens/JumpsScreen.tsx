import React from 'react';
import {View, Text, StyleSheet} from 'react-native';

const JumpsScreen: React.FC = () => {
  return (
    <View style={styles.container}>
      <Text style={styles.title}>Sprünge</Text>
      <Text>Liste der Sprünge wird hier angezeigt</Text>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    padding: 16,
  },
  title: {
    fontSize: 24,
    fontWeight: 'bold',
    marginBottom: 16,
  },
});

export default JumpsScreen;
