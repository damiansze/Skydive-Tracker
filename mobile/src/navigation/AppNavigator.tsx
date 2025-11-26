import React from 'react';
import {createBottomTabNavigator} from '@react-navigation/bottom-tabs';
import {createStackNavigator} from '@react-navigation/stack';
import JumpsScreen from '../screens/JumpsScreen';
import ProfileScreen from '../screens/ProfileScreen';
import StatisticsScreen from '../screens/StatisticsScreen';
import JumpDetailScreen from '../screens/JumpDetailScreen';

const Tab = createBottomTabNavigator();
const Stack = createStackNavigator();

const JumpsStack = () => (
  <Stack.Navigator>
    <Stack.Screen 
      name="JumpsList" 
      component={JumpsScreen}
      options={{title: 'Sprünge'}}
    />
    <Stack.Screen 
      name="JumpDetail" 
      component={JumpDetailScreen}
      options={{title: 'Sprung-Details'}}
    />
  </Stack.Navigator>
);

const AppNavigator: React.FC = () => {
  return (
    <Tab.Navigator
      screenOptions={{
        tabBarActiveTintColor: '#007AFF',
        tabBarInactiveTintColor: '#999',
        headerStyle: {
          backgroundColor: '#fff',
        },
        headerTintColor: '#333',
        headerTitleStyle: {
          fontWeight: 'bold',
        },
      }}>
      <Tab.Screen 
        name="Jumps" 
        component={JumpsStack}
        options={{
          tabBarLabel: 'Sprünge',
          headerShown: false,
        }}
      />
      <Tab.Screen 
        name="Statistics" 
        component={StatisticsScreen}
        options={{
          tabBarLabel: 'Statistik',
          title: 'Statistik',
        }}
      />
      <Tab.Screen 
        name="Profile" 
        component={ProfileScreen}
        options={{
          tabBarLabel: 'Profil',
          title: 'Profil',
        }}
      />
    </Tab.Navigator>
  );
};

export default AppNavigator;
