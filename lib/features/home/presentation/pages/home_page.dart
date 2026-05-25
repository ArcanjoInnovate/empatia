import 'package:empatia/core/models/user_model.dart';
import 'package:flutter/material.dart';
import 'dart:async';

class HomePage extends StatefulWidget {
  final UserModel user;
  
  const HomePage({
    Key? key,
    required this.user,
  }) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PageController _adsController = PageController();
  int _currentAdPage = 0;
  Timer? _adTimer;

  final List<Map<String, dynamic>> _ads = [
    {
      'title': 'Bingo',
      'subtitle': 'Pingo',
      'emoji': '🚀',
      'colors': [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
    },
    {
      'title': 'Novidade',
      'subtitle': 'em breve',
      'emoji': '🎈',
      'colors': [Color(0xFFFF6B9D), Color(0xFFFF1493)],
    },
    {
      'title': 'Diversão',
      'subtitle': 'garantida',
      'emoji': '🎮',
      'colors': [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
    },
  ];

  @override
  void initState() {
    super.initState();
    _startAdTimer();
  }

  void _startAdTimer() {
    _adTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_currentAdPage < _ads.length - 1) {
        _currentAdPage++;
      } else {
        _currentAdPage = 0;
      }
      _adsController.animateToPage(
        _currentAdPage,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _adTimer?.cancel();
    _adsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          // Header azul com EMPATIA e saudação personalizada
          _buildHeader(),
          
          // Corpo com scroll
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  
                  // Carrossel de anúncios
                  _buildAdsCarousel(),
                  
                  const SizedBox(height: 24),
                  
                  // Lista de sonhos do usuário
                  _buildDreamsList(),
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    // Saudação baseada na hora do dia
    final hour = DateTime.now().hour;
    String greeting = 'Oi';
    String emoji = '👋';
    
    if (hour >= 0 && hour < 12) {
      greeting = 'Bom dia';
      emoji = '🌅';
    } else if (hour >= 12 && hour < 18) {
      greeting = 'Boa tarde';
      emoji = '☀️';
    } else {
      greeting = 'Boa noite';
      emoji = '🌙';
    }

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              // Logo e saudação
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'EMPATIA',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          emoji,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$greeting, ${widget.user.name?.split(' ').first ?? 'Amiga'}!',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Notificações
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.notifications_outlined,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdsCarousel() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          SizedBox(
            height: 140,
            child: PageView.builder(
              controller: _adsController,
              onPageChanged: (index) {
                setState(() => _currentAdPage = index);
              },
              itemCount: _ads.length,
              itemBuilder: (context, index) {
                final ad = _ads[index];
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: ad['colors'],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: ad['colors'][0].withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Fundo decorativo
                      Positioned(
                        right: -20,
                        top: -20,
                        child: Text(
                          ad['emoji'],
                          style: TextStyle(
                            fontSize: 120,
                            color: Colors.white.withOpacity(0.15),
                          ),
                        ),
                      ),
                      
                      // Conteúdo
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            // Emoji grande
                            Text(
                              ad['emoji'],
                              style: const TextStyle(fontSize: 60),
                            ),
                            const SizedBox(width: 16),
                            
                            // Textos
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ad['title'],
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    ad['subtitle'],
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          
          // Indicadores de página
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_ads.length, (index) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentAdPage == index ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentAdPage == index
                      ? const Color(0xFF2563EB)
                      : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildDreamsList() {
    // Usa os sonhos do usuário se existirem, senão mostra exemplos
    final dreams = widget.user.dreams;
    
    if (dreams == null || dreams.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const Text(
              'Sonhos 💭',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Color(0xFF1E3A8A),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text('🌟', style: TextStyle(fontSize: 60)),
                  const SizedBox(height: 12),
                  Text(
                    'Nenhum sonho ainda',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Adicione seus sonhos no perfil!',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              const Text(
                'Meus Sonhos ',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1E3A8A),
                ),
              ),
              Text(
                '(${dreams.length})',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.grey.shade400,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // Lista de sonhos reais do usuário
        ...dreams.map((dream) => _buildDreamCard(
          title: dream.title ?? 'Sem título',
          subtitle: dream.date ?? '',
          emoji: dream.emoji ?? '💭',
          progress: dream.progress ?? 0.0,
          likes: 0, // Implementar likes no futuro
          comments: 0, // Implementar comentários no futuro
        )),
      ],
    );
  }

  Widget _buildDreamCard({
    required String title,
    required String subtitle,
    required String emoji,
    required double progress,
    required int likes,
    required int comments,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar do usuário
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF6B9D), Color(0xFFFF1493)],
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Center(
                  child: Text(
                    widget.user.profileImage ?? '👩',
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              
              // Textos
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E3A8A),
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              // Progresso
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: progress >= 0.7
                        ? [const Color(0xFF4ADE80), const Color(0xFF22C55E)]
                        : progress >= 0.4
                            ? [const Color(0xFFFFC837), const Color(0xFFFFD700)]
                            : [const Color(0xFFFF6B9D), const Color(0xFFFF1493)],
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  '${(progress * 100).toInt()}%',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Área da imagem do desenho/sonho
          Container(
            width: double.infinity,
            height: 180,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFE0F2FE),
                  Color(0xFFFFF9E6),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF2563EB).withOpacity(0.2),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 80),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Barra de progresso
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                progress >= 0.7
                    ? const Color(0xFF4ADE80)
                    : progress >= 0.4
                        ? const Color(0xFFFFC837)
                        : const Color(0xFFFF6B9D),
              ),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 16),
          
          // Likes, comentários e salvar
          Row(
            children: [
              _buildInteractionButton(
                icon: Icons.favorite,
                count: likes,
                color: const Color(0xFFFF6B9D),
              ),
              const SizedBox(width: 16),
              _buildInteractionButton(
                icon: Icons.chat_bubble_outline,
                count: comments,
                color: const Color(0xFF2563EB),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFC837), Color(0xFFFFD700)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFC837).withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  children: [
                    Text(
                      'Salvar',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 6),
                    Text('💾', style: TextStyle(fontSize: 16)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInteractionButton({
    required IconData icon,
    required int count,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 6),
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}