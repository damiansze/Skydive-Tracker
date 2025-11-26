import React, {useState, useEffect} from 'react';
import {
  View,
  Text,
  StyleSheet,
  FlatList,
  TouchableOpacity,
  Alert,
} from 'react-native';
import {useNavigation} from '@react-navigation/native';
import JumpService from '../services/jumps/JumpService';
import {Jump} from '../models/Jump';
import {formatDate} from '../utils/dateUtils';

const JumpsScreen: React.FC = () => {
  const navigation = useNavigation();
  const [jumps, setJumps] = useState<Jump[]>([]);
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
      Alert.alert('Fehler', 'Sprünge konnten nicht geladen werden');
    } finally {
      setLoading(false);
    }
  };

  const handleAddJump = () => {
    navigation.navigate('JumpDetail' as never, {jumpId: null} as never);
  };

  const handleJumpPress = (jump: Jump) => {
    navigation.navigate('JumpDetail' as never, {jumpId: jump.id} as never);
  };

  const renderJumpItem = ({item}: {item: Jump}) => (
    <TouchableOpacity
      style={styles.jumpItem}
      onPress={() => handleJumpPress(item)}>
      <View style={styles.jumpHeader}>
        <Text style={styles.jumpDate}>{formatDate(item.date)}</Text>
        <Text style={styles.jumpLocation}>{item.location}</Text>
      </View>
      <Text style={styles.jumpAltitude}>{item.altitude} ft</Text>
      {item.checklistCompleted && (
        <Text style={styles.checklistBadge}>✓ Checkliste erledigt</Text>
      )}
    </TouchableOpacity>
  );

  if (loading) {
    return (
      <View style={styles.container}>
        <Text>Lade Sprünge...</Text>
      </View>
    );
  }

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.title}>Sprünge</Text>
        <TouchableOpacity style={styles.addButton} onPress={handleAddJump}>
          <Text style={styles.addButtonText}>+ Neuer Sprung</Text>
        </TouchableOpacity>
      </View>

      {jumps.length === 0 ? (
        <View style={styles.emptyContainer}>
          <Text style={styles.emptyText}>Noch keine Sprünge erfasst</Text>
          <TouchableOpacity style={styles.emptyButton} onPress={handleAddJump}>
            <Text style={styles.emptyButtonText}>Ersten Sprung erfassen</Text>
          </TouchableOpacity>
        </View>
      ) : (
        <FlatList
          data={jumps}
          renderItem={renderJumpItem}
          keyExtractor={item => item.id}
          contentContainerStyle={styles.list}
        />
      )}
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f5f5f5',
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    padding: 16,
    backgroundColor: '#fff',
    borderBottomWidth: 1,
    borderBottomColor: '#e0e0e0',
  },
  title: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#333',
  },
  addButton: {
    backgroundColor: '#007AFF',
    paddingHorizontal: 16,
    paddingVertical: 8,
    borderRadius: 8,
  },
  addButtonText: {
    color: '#fff',
    fontWeight: '600',
  },
  list: {
    padding: 16,
  },
  jumpItem: {
    backgroundColor: '#fff',
    padding: 16,
    borderRadius: 8,
    marginBottom: 12,
    shadowColor: '#000',
    shadowOffset: {width: 0, height: 2},
    shadowOpacity: 0.1,
    shadowRadius: 4,
    elevation: 3,
  },
  jumpHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: 8,
  },
  jumpDate: {
    fontSize: 16,
    fontWeight: '600',
    color: '#333',
  },
  jumpLocation: {
    fontSize: 14,
    color: '#666',
  },
  jumpAltitude: {
    fontSize: 14,
    color: '#007AFF',
    marginTop: 4,
  },
  checklistBadge: {
    fontSize: 12,
    color: '#34C759',
    marginTop: 8,
    fontWeight: '500',
  },
  emptyContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    padding: 32,
  },
  emptyText: {
    fontSize: 18,
    color: '#666',
    marginBottom: 16,
    textAlign: 'center',
  },
  emptyButton: {
    backgroundColor: '#007AFF',
    paddingHorizontal: 24,
    paddingVertical: 12,
    borderRadius: 8,
  },
  emptyButtonText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: '600',
  },
});

export default JumpsScreen;
