// lib/features/home/presentation/constants/home_constants.dart
//
// Constantes visuais, cores, dados mock e lista de filtros do Home.
// ─────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:empatia/features/home/data/models/feed_item_.dart';

// ─────────────────────────────────────────────────────────────
// CORES
// ─────────────────────────────────────────────────────────────

const kGradientStart = Color(0xFF1A1060);
const kGradientMid   = Color(0xFF3B1FA0);
const kGradientEnd   = Color(0xFF6A1B9A);

const kGold   = Color(0xFFFFD700);
const kSilver = Color(0xFFB0BEC5);
const kBronze = Color(0xFFCD7F32);

const kPurpleSoft = Color(0xFFF0E6FF);
const kPinkSoft   = Color(0xFFFFE4F0);

// ─────────────────────────────────────────────────────────────
// DADOS MOCK — substituir por dados reais futuramente
// ─────────────────────────────────────────────────────────────

const kMockDonors = [
  {
    'name': 'Ana Carolina Mendes',
    'emoji': '👩',
    'dreams': 18,
    'donations': 47,
    'streak': 6,
    'score': 1240,
    'badge': '👑 Herói da Semana',
    'city': 'São Paulo, SP',
  },
  {
    'name': 'Pedro Augusto Lima',
    'emoji': '👨',
    'dreams': 11,
    'donations': 38,
    'streak': 4,
    'score': 980,
    'badge': '✨ Transformando Vidas',
    'city': 'Belo Horizonte, MG',
  },
  {
    'name': 'Mariana Silva',
    'emoji': '👩‍🦱',
    'dreams': 9,
    'donations': 31,
    'streak': 3,
    'score': 810,
    'badge': '❤️ Guardiã dos Sonhos',
    'city': 'Rio de Janeiro, RJ',
  },
  {
    'name': 'João Ferreira',
    'emoji': '🧔',
    'dreams': 6,
    'donations': 24,
    'streak': 2,
    'score': 620,
    'badge': '🌟 Doador Destaque',
    'city': 'Curitiba, PR',
  },
  {
    'name': 'Fernanda Costa',
    'emoji': '👩‍🦰',
    'dreams': 5,
    'donations': 19,
    'streak': 2,
    'score': 490,
    'badge': '🏆 Campeão da Generosidade',
    'city': 'Fortaleza, CE',
  },
];

// ─────────────────────────────────────────────────────────────
// INSIGHTS — blocos inseridos no feed a cada 4 cards
// ─────────────────────────────────────────────────────────────

const kInsights = [
  {
    'emoji': '✨',
    'text': '124 sonhos já foram realizados',
    'sub': 'Graças à nossa comunidade incrível',
    'gradient': [Color(0xFF6C3FE8), Color(0xFF9B59B6)],
  },
  {
    'emoji': '❤️',
    'text': 'Mais de 500 famílias impactadas',
    'sub': 'Cada doação faz diferença real',
    'gradient': [Color(0xFFE91E8C), Color(0xFFFF6B9D)],
  },
  {
    'emoji': '🏆',
    'text': 'Conheça os maiores doadores',
    'sub': 'Veja quem está transformando vidas',
    'gradient': [Color(0xFF1565C0), Color(0xFF42A5F5)],
  },
  {
    'emoji': '🎁',
    'text': 'Sua próxima doação pode mudar tudo',
    'sub': 'Um pequeno gesto, um grande impacto',
    'gradient': [Color(0xFF2E7D32), Color(0xFF66BB6A)],
  },
];

// ─────────────────────────────────────────────────────────────
// CHIPS DE FILTRO RÁPIDO
// ─────────────────────────────────────────────────────────────

const kFilterChips = [
  {'label': 'Todos',   'emoji': '🌟', 'type': null},
  {'label': 'Sonhos',  'emoji': '💭', 'type': FeedItemType.dream},
  {'label': 'Doações', 'emoji': '🎁', 'type': FeedItemType.donation},
];