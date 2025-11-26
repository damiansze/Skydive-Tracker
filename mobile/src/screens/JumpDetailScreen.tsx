import React, {useState, useEffect} from 'react';
import {
  View,
  Text,
  StyleSheet,
  TextInput,
  TouchableOpacity,
  ScrollView,
  Alert,
  Switch,
} from 'react-native';
import DateTimePicker from '@react-native-community/datetimepicker';
import {useRoute, useNavigation} from '@react-navigation/native';
import JumpService from '../services/jumps/JumpService';
import EquipmentService from '../services/equipment/EquipmentService';
import {Jump, JumpCreateInput} from '../models/Jump';
import {Equipment} from '../models/Equipment';
import {formatDateTime} from '../utils/dateUtils';

const JumpDetailScreen: React.FC = () => {
  const route = useRoute();
  const navigation = useNavigation();
  const jumpId = (route.params as any)?.jumpId;

  const [date, setDate] = useState(new Date());
  const [showDatePicker, setShowDatePicker] = useState(false);
  const [location, setLocation] = useState('');
  const [altitude, setAltitude] = useState('');
  const [notes, setNotes] = useState('');
  const [checklistCompleted, setChecklistCompleted] = useState(false);
  const [availableEquipment, setAvailableEquipment] = useState<Equipment[]>([]);
  const [selectedEquipment, setSelectedEquipment] = useState<string[]>([]);

  useEffect(() => {
    loadEquipment();
    if (jumpId) {
      loadJump();
    }
  }, [jumpId]);

  const loadEquipment = async () => {
    try {
      const equipment = await EquipmentService.getAllEquipment();
      setAvailableEquipment(equipment);
    } catch (error) {
      console.error('Error loading equipment:', error);
    }
  };

  const loadJump = async () => {
    try {
      const jump = await JumpService.getJumpById(jumpId);
      if (jump) {
        setDate(jump.date);
        setLocation(jump.location);
        setAltitude(jump.altitude.toString());
        setNotes(jump.notes || '');
        setChecklistCompleted(jump.checklistCompleted);
        setSelectedEquipment(jump.equipmentIds);
      }
    } catch (error) {
      console.error('Error loading jump:', error);
      Alert.alert('Fehler', 'Sprung konnte nicht geladen werden');
    }
  };

  const handleSave = async () => {
    if (!location.trim()) {
      Alert.alert('Fehler', 'Bitte gib einen Ort ein');
      return;
    }

    if (!altitude.trim() || isNaN(Number(altitude))) {
      Alert.alert('Fehler', 'Bitte gib eine gültige Höhe ein');
      return;
    }

    try {
      const jumpData: JumpCreateInput = {
        date,
        location: location.trim(),
        altitude: Number(altitude),
        equipmentIds: selectedEquipment,
        checklistCompleted,
        notes: notes.trim() || undefined,
      };

      if (jumpId) {
        // Update existing jump (would need update method)
        Alert.alert('Info', 'Update-Funktion noch nicht implementiert');
      } else {
        await JumpService.createJump(jumpData);
        Alert.alert('Erfolg', 'Sprung gespeichert', [
          {text: 'OK', onPress: () => navigation.goBack()},
        ]);
      }
    } catch (error) {
      console.error('Error saving jump:', error);
      Alert.alert('Fehler', 'Sprung konnte nicht gespeichert werden');
    }
  };

  const toggleEquipment = (equipmentId: string) => {
    setSelectedEquipment(prev =>
      prev.includes(equipmentId)
        ? prev.filter(id => id !== equipmentId)
        : [...prev, equipmentId],
    );
  };

  return (
    <ScrollView style={styles.container}>
      <View style={styles.form}>
        <View style={styles.section}>
          <Text style={styles.label}>Datum & Zeit</Text>
          <TouchableOpacity
            style={styles.dateButton}
            onPress={() => setShowDatePicker(true)}>
            <Text style={styles.dateText}>{formatDateTime(date)}</Text>
          </TouchableOpacity>
          {showDatePicker && (
            <DateTimePicker
              value={date}
              mode="datetime"
              display="default"
              onChange={(event, selectedDate) => {
                setShowDatePicker(false);
                if (selectedDate) {
                  setDate(selectedDate);
                }
              }}
            />
          )}
        </View>

        <View style={styles.section}>
          <Text style={styles.label}>Ort *</Text>
          <TextInput
            style={styles.input}
            value={location}
            onChangeText={setLocation}
            placeholder="z.B. Skydive Center XYZ"
            placeholderTextColor="#999"
          />
        </View>

        <View style={styles.section}>
          <Text style={styles.label}>Höhe (ft) *</Text>
          <TextInput
            style={styles.input}
            value={altitude}
            onChangeText={setAltitude}
            placeholder="z.B. 14000"
            keyboardType="numeric"
            placeholderTextColor="#999"
          />
        </View>

        <View style={styles.section}>
          <Text style={styles.label}>Verwendetes Equipment</Text>
          {availableEquipment.length === 0 ? (
            <Text style={styles.hint}>
              Noch kein Equipment erfasst. Bitte zuerst im Profil Equipment
              hinzufügen.
            </Text>
          ) : (
            availableEquipment.map(equipment => (
              <TouchableOpacity
                key={equipment.id}
                style={[
                  styles.equipmentItem,
                  selectedEquipment.includes(equipment.id) &&
                    styles.equipmentItemSelected,
                ]}
                onPress={() => toggleEquipment(equipment.id)}>
                <Text
                  style={[
                    styles.equipmentText,
                    selectedEquipment.includes(equipment.id) &&
                      styles.equipmentTextSelected,
                  ]}>
                  {equipment.name} ({equipment.type})
                </Text>
                {selectedEquipment.includes(equipment.id) && (
                  <Text style={styles.checkmark}>✓</Text>
                )}
              </TouchableOpacity>
            ))
          )}
        </View>

        <View style={styles.section}>
          <View style={styles.checklistRow}>
            <Text style={styles.label}>Checkliste erledigt</Text>
            <Switch
              value={checklistCompleted}
              onValueChange={setChecklistCompleted}
            />
          </View>
        </View>

        <View style={styles.section}>
          <Text style={styles.label}>Notizen</Text>
          <TextInput
            style={[styles.input, styles.textArea]}
            value={notes}
            onChangeText={setNotes}
            placeholder="Zusätzliche Notizen..."
            multiline
            numberOfLines={4}
            placeholderTextColor="#999"
          />
        </View>

        <TouchableOpacity style={styles.saveButton} onPress={handleSave}>
          <Text style={styles.saveButtonText}>Speichern</Text>
        </TouchableOpacity>
      </View>
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f5f5f5',
  },
  form: {
    padding: 16,
  },
  section: {
    marginBottom: 24,
  },
  label: {
    fontSize: 16,
    fontWeight: '600',
    color: '#333',
    marginBottom: 8,
  },
  input: {
    backgroundColor: '#fff',
    borderWidth: 1,
    borderColor: '#e0e0e0',
    borderRadius: 8,
    padding: 12,
    fontSize: 16,
    color: '#333',
  },
  textArea: {
    height: 100,
    textAlignVertical: 'top',
  },
  dateButton: {
    backgroundColor: '#fff',
    borderWidth: 1,
    borderColor: '#e0e0e0',
    borderRadius: 8,
    padding: 12,
  },
  dateText: {
    fontSize: 16,
    color: '#333',
  },
  equipmentItem: {
    backgroundColor: '#fff',
    borderWidth: 1,
    borderColor: '#e0e0e0',
    borderRadius: 8,
    padding: 12,
    marginBottom: 8,
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  equipmentItemSelected: {
    backgroundColor: '#E3F2FD',
    borderColor: '#007AFF',
  },
  equipmentText: {
    fontSize: 16,
    color: '#333',
  },
  equipmentTextSelected: {
    color: '#007AFF',
    fontWeight: '600',
  },
  checkmark: {
    color: '#007AFF',
    fontSize: 18,
    fontWeight: 'bold',
  },
  checklistRow: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  hint: {
    fontSize: 14,
    color: '#666',
    fontStyle: 'italic',
  },
  saveButton: {
    backgroundColor: '#007AFF',
    padding: 16,
    borderRadius: 8,
    alignItems: 'center',
    marginTop: 16,
  },
  saveButtonText: {
    color: '#fff',
    fontSize: 18,
    fontWeight: '600',
  },
});

export default JumpDetailScreen;
