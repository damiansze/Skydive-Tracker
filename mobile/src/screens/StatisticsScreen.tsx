import React from 'react';
import {View, Text, StyleSheet} from 'react-native';

const StatisticsScreen: React.FC = () => {
  return (
    <View style={styles.container}>
      <Text style={styles.title}>Statistik</Text>
      <Text>Statistiken werden hier angezeigt</Text>
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

export default StatisticsScreen;
