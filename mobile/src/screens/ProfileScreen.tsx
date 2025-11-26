import React, {useState, useEffect} from 'react';
import {
  View,
  Text,
  StyleSheet,
  TextInput,
  TouchableOpacity,
  ScrollView,
  Alert,
  FlatList,
} from 'react-native';
import ProfileService from '../services/profile/ProfileService';
import EquipmentService from '../services/equipment/EquipmentService';
import {Profile} from '../models/Profile';
import {Equipment, EquipmentType} from '../models/Equipment';

const ProfileScreen: React.FC = () => {
  const [profile, setProfile] = useState<Profile | null>(null);
  const [name, setName] = useState('');
  const [licenseNumber, setLicenseNumber] = useState('');
  const [licenseType, setLicenseType] = useState('');
  const [equipment, setEquipment] = useState<Equipment[]>([]);
  const [showEquipmentForm, setShowEquipmentForm] = useState(false);
  const [newEquipmentName, setNewEquipmentName] = useState('');
  const [newEquipmentType, setNewEquipmentType] = useState<EquipmentType>(
    EquipmentType.PARACHUTE,
  );

  useEffect(() => {
    loadProfile();
    loadEquipment();
  }, []);

  const loadProfile = async () => {
    try {
      const profileData = await ProfileService.getProfile();
      if (profileData) {
        setProfile(profileData);
        setName(profileData.name);
        setLicenseNumber(profileData.licenseNumber || '');
        setLicenseType(profileData.licenseType || '');
      }
    } catch (error) {
      console.error('Error loading profile:', error);
    }
  };

  const loadEquipment = async () => {
    try {
      const equipmentList = await EquipmentService.getAllEquipment();
      setEquipment(equipmentList);
    } catch (error) {
      console.error('Error loading equipment:', error);
    }
  };

  const handleSaveProfile = async () => {
    if (!name.trim()) {
      Alert.alert('Fehler', 'Bitte gib deinen Namen ein');
      return;
    }

    try {
      await ProfileService.createOrUpdateProfile({
        name: name.trim(),
        licenseNumber: licenseNumber.trim() || undefined,
        licenseType: licenseType.trim() || undefined,
      });
      Alert.alert('Erfolg', 'Profil gespeichert');
      loadProfile();
    } catch (error) {
      console.error('Error saving profile:', error);
      Alert.alert('Fehler', 'Profil konnte nicht gespeichert werden');
    }
  };

  const handleAddEquipment = async () => {
    if (!newEquipmentName.trim()) {
      Alert.alert('Fehler', 'Bitte gib einen Namen ein');
      return;
    }

    try {
      await EquipmentService.createEquipment({
        name: newEquipmentName.trim(),
        type: newEquipmentType,
      });
      setNewEquipmentName('');
      setShowEquipmentForm(false);
      Alert.alert('Erfolg', 'Equipment hinzugefügt');
      loadEquipment();
    } catch (error) {
      console.error('Error adding equipment:', error);
      Alert.alert('Fehler', 'Equipment konnte nicht hinzugefügt werden');
    }
  };

  const handleDeleteEquipment = (equipmentId: string) => {
    Alert.alert(
      'Equipment löschen',
      'Möchtest du dieses Equipment wirklich löschen?',
      [
        {text: 'Abbrechen', style: 'cancel'},
        {
          text: 'Löschen',
          style: 'destructive',
          onPress: async () => {
            try {
              await EquipmentService.deleteEquipment(equipmentId);
              loadEquipment();
            } catch (error) {
              Alert.alert('Fehler', 'Equipment konnte nicht gelöscht werden');
            }
          },
        },
      ],
    );
  };

  const renderEquipmentItem = ({item}: {item: Equipment}) => (
    <View style={styles.equipmentItem}>
      <View style={styles.equipmentInfo}>
        <Text style={styles.equipmentName}>{item.name}</Text>
        <Text style={styles.equipmentType}>{item.type}</Text>
      </View>
      <TouchableOpacity
        style={styles.deleteButton}
        onPress={() => handleDeleteEquipment(item.id)}>
        <Text style={styles.deleteButtonText}>Löschen</Text>
      </TouchableOpacity>
    </View>
  );

  return (
    <ScrollView style={styles.container}>
      <View style={styles.section}>
        <Text style={styles.sectionTitle}>Persönliche Daten</Text>

        <View style={styles.inputGroup}>
          <Text style={styles.label}>Name *</Text>
          <TextInput
            style={styles.input}
            value={name}
            onChangeText={setName}
            placeholder="Dein Name"
            placeholderTextColor="#999"
          />
        </View>

        <View style={styles.inputGroup}>
          <Text style={styles.label}>Lizenznummer</Text>
          <TextInput
            style={styles.input}
            value={licenseNumber}
            onChangeText={setLicenseNumber}
            placeholder="z.B. D-12345"
            placeholderTextColor="#999"
          />
        </View>

        <View style={styles.inputGroup}>
          <Text style={styles.label}>Lizenztyp</Text>
          <TextInput
            style={styles.input}
            value={licenseType}
            onChangeText={setLicenseType}
            placeholder="z.B. A-Lizenz"
            placeholderTextColor="#999"
          />
        </View>

        {profile && (
          <View style={styles.stats}>
            <Text style={styles.statsText}>
              Gesamte Sprünge: {profile.totalJumps}
            </Text>
          </View>
        )}

        <TouchableOpacity style={styles.saveButton} onPress={handleSaveProfile}>
          <Text style={styles.saveButtonText}>Profil speichern</Text>
        </TouchableOpacity>
      </View>

      <View style={styles.section}>
        <View style={styles.sectionHeader}>
          <Text style={styles.sectionTitle}>Equipment</Text>
          <TouchableOpacity
            style={styles.addButton}
            onPress={() => setShowEquipmentForm(!showEquipmentForm)}>
            <Text style={styles.addButtonText}>
              {showEquipmentForm ? 'Abbrechen' : '+ Hinzufügen'}
            </Text>
          </TouchableOpacity>
        </View>

        {showEquipmentForm && (
          <View style={styles.equipmentForm}>
            <TextInput
              style={styles.input}
              value={newEquipmentName}
              onChangeText={setNewEquipmentName}
              placeholder="Equipment-Name"
              placeholderTextColor="#999"
            />
            <View style={styles.typeSelector}>
              {Object.values(EquipmentType).map(type => (
                <TouchableOpacity
                  key={type}
                  style={[
                    styles.typeButton,
                    newEquipmentType === type && styles.typeButtonSelected,
                  ]}
                  onPress={() => setNewEquipmentType(type)}>
                  <Text
                    style={[
                      styles.typeButtonText,
                      newEquipmentType === type &&
                        styles.typeButtonTextSelected,
                    ]}>
                    {type}
                  </Text>
                </TouchableOpacity>
              ))}
            </View>
            <TouchableOpacity
              style={styles.addEquipmentButton}
              onPress={handleAddEquipment}>
              <Text style={styles.addEquipmentButtonText}>Hinzufügen</Text>
            </TouchableOpacity>
          </View>
        )}

        {equipment.length === 0 ? (
          <Text style={styles.emptyText}>Noch kein Equipment erfasst</Text>
        ) : (
          <FlatList
            data={equipment}
            renderItem={renderEquipmentItem}
            keyExtractor={item => item.id}
            scrollEnabled={false}
          />
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
  section: {
    backgroundColor: '#fff',
    padding: 16,
    marginBottom: 16,
  },
  sectionHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 16,
  },
  sectionTitle: {
    fontSize: 20,
    fontWeight: 'bold',
    color: '#333',
    marginBottom: 16,
  },
  inputGroup: {
    marginBottom: 16,
  },
  label: {
    fontSize: 14,
    fontWeight: '600',
    color: '#333',
    marginBottom: 8,
  },
  input: {
    backgroundColor: '#f9f9f9',
    borderWidth: 1,
    borderColor: '#e0e0e0',
    borderRadius: 8,
    padding: 12,
    fontSize: 16,
    color: '#333',
  },
  stats: {
    backgroundColor: '#E3F2FD',
    padding: 12,
    borderRadius: 8,
    marginBottom: 16,
  },
  statsText: {
    fontSize: 16,
    color: '#007AFF',
    fontWeight: '600',
  },
  saveButton: {
    backgroundColor: '#007AFF',
    padding: 16,
    borderRadius: 8,
    alignItems: 'center',
  },
  saveButtonText: {
    color: '#fff',
    fontSize: 18,
    fontWeight: '600',
  },
  addButton: {
    backgroundColor: '#34C759',
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 6,
  },
  addButtonText: {
    color: '#fff',
    fontWeight: '600',
  },
  equipmentForm: {
    backgroundColor: '#f9f9f9',
    padding: 12,
    borderRadius: 8,
    marginBottom: 16,
  },
  typeSelector: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    marginTop: 12,
    marginBottom: 12,
  },
  typeButton: {
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 6,
    backgroundColor: '#fff',
    borderWidth: 1,
    borderColor: '#e0e0e0',
    marginRight: 8,
    marginBottom: 8,
  },
  typeButtonSelected: {
    backgroundColor: '#007AFF',
    borderColor: '#007AFF',
  },
  typeButtonText: {
    fontSize: 12,
    color: '#333',
  },
  typeButtonTextSelected: {
    color: '#fff',
    fontWeight: '600',
  },
  addEquipmentButton: {
    backgroundColor: '#007AFF',
    padding: 12,
    borderRadius: 8,
    alignItems: 'center',
  },
  addEquipmentButtonText: {
    color: '#fff',
    fontWeight: '600',
  },
  equipmentItem: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    padding: 12,
    backgroundColor: '#f9f9f9',
    borderRadius: 8,
    marginBottom: 8,
  },
  equipmentInfo: {
    flex: 1,
  },
  equipmentName: {
    fontSize: 16,
    fontWeight: '600',
    color: '#333',
  },
  equipmentType: {
    fontSize: 14,
    color: '#666',
    marginTop: 4,
  },
  deleteButton: {
    backgroundColor: '#FF3B30',
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 6,
  },
  deleteButtonText: {
    color: '#fff',
    fontSize: 12,
    fontWeight: '600',
  },
  emptyText: {
    fontSize: 14,
    color: '#666',
    textAlign: 'center',
    padding: 16,
  },
});

export default ProfileScreen;
