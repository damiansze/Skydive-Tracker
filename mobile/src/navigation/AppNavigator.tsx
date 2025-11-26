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
        headerShown: false,
      }}>
      <Tab.Screen 
        name="Jumps" 
        component={JumpsStack}
        options={{
          tabBarLabel: 'Sprünge',
        }}
      />
      <Tab.Screen 
        name="Statistics" 
        component={StatisticsScreen}
        options={{
          tabBarLabel: 'Statistik',
        }}
      />
      <Tab.Screen 
        name="Profile" 
        component={ProfileScreen}
        options={{
          tabBarLabel: 'Profil',
        }}
      />
    </Tab.Navigator>
  );
};

export default AppNavigator;
