import React, {useState, useEffect} from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  TextInput,
} from 'react-native';
import JumpService from '../services/jumps/JumpService';
import {Jump} from '../models/Jump';

const StatisticsScreen: React.FC = () => {
  const [jumps, setJumps] = useState<Jump[]>([]);
  const [locationFilter, setLocationFilter] = useState('');
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadJumps();
  }, []);

  const loadJumps = async () => {
    try {
      const allJumps = await JumpService.getAllJumps();
      setJumps(allJumps);
    } catch (error) {
      console.error('Error loading jumps:', error);
    } finally {
      setLoading(false);
    }
  };

  const filteredJumps = jumps.filter(jump =>
    locationFilter
      ? jump.location.toLowerCase().includes(locationFilter.toLowerCase())
      : true,
  );

  const uniqueLocations = Array.from(
    new Set(jumps.map(jump => jump.location)),
  );

  const totalJumps = filteredJumps.length;
  const averageAltitude =
    filteredJumps.length > 0
      ? Math.round(
          filteredJumps.reduce((sum, jump) => sum + jump.altitude, 0) /
            filteredJumps.length,
        )
      : 0;

  const jumpsByLocation = uniqueLocations.map(location => ({
    location,
    count: jumps.filter(j => j.location === location).length,
  }));

  if (loading) {
    return (
      <View style={styles.container}>
        <Text>Lade Statistiken...</Text>
      </View>
    );
  }

  return (
    <ScrollView style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.title}>Statistik</Text>
      </View>

      <View style={styles.section}>
        <View style={styles.statCard}>
          <Text style={styles.statValue}>{totalJumps}</Text>
          <Text style={styles.statLabel}>
            {locationFilter ? 'Gefilterte Sprünge' : 'Gesamte Sprünge'}
          </Text>
        </View>

        <View style={styles.statCard}>
          <Text style={styles.statValue}>{averageAltitude} ft</Text>
          <Text style={styles.statLabel}>Durchschnittliche Höhe</Text>
        </View>
      </View>

      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Nach Ort filtern</Text>
        <TextInput
          style={styles.filterInput}
          value={locationFilter}
          onChangeText={setLocationFilter}
          placeholder="Ort eingeben..."
          placeholderTextColor="#999"
        />
        {locationFilter && (
          <TouchableOpacity
            style={styles.clearButton}
            onPress={() => setLocationFilter('')}>
            <Text style={styles.clearButtonText}>Filter zurücksetzen</Text>
          </TouchableOpacity>
        )}
      </View>

      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Sprünge nach Ort</Text>
        {jumpsByLocation.length === 0 ? (
          <Text style={styles.emptyText}>Noch keine Sprünge erfasst</Text>
        ) : (
          jumpsByLocation
            .sort((a, b) => b.count - a.count)
            .map(({location, count}) => (
              <View key={location} style={styles.locationItem}>
                <Text style={styles.locationName}>{location}</Text>
                <Text style={styles.locationCount}>{count} Sprünge</Text>
              </View>
            ))
        )}
      </View>
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f5f5f5',
  },
  header: {
    backgroundColor: '#fff',
    padding: 16,
    borderBottomWidth: 1,
    borderBottomColor: '#e0e0e0',
  },
  title: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#333',
  },
  section: {
    backgroundColor: '#fff',
    padding: 16,
    marginTop: 16,
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: '600',
    color: '#333',
    marginBottom: 12,
  },
  statCard: {
    backgroundColor: '#E3F2FD',
    padding: 20,
    borderRadius: 12,
    alignItems: 'center',
    marginBottom: 12,
  },
  statValue: {
    fontSize: 36,
    fontWeight: 'bold',
    color: '#007AFF',
    marginBottom: 4,
  },
  statLabel: {
    fontSize: 14,
    color: '#666',
  },
  filterInput: {
    backgroundColor: '#f9f9f9',
    borderWidth: 1,
    borderColor: '#e0e0e0',
    borderRadius: 8,
    padding: 12,
    fontSize: 16,
    color: '#333',
  },
  clearButton: {
    marginTop: 8,
    padding: 8,
    alignItems: 'center',
  },
  clearButtonText: {
    color: '#007AFF',
    fontSize: 14,
  },
  locationItem: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    padding: 12,
    backgroundColor: '#f9f9f9',
    borderRadius: 8,
    marginBottom: 8,
  },
  locationName: {
    fontSize: 16,
    color: '#333',
    flex: 1,
  },
  locationCount: {
    fontSize: 16,
    fontWeight: '600',
    color: '#007AFF',
  },
  emptyText: {
    fontSize: 14,
    color: '#666',
    textAlign: 'center',
    padding: 16,
  },
});

export default StatisticsScreen;
