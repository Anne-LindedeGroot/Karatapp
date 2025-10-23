import 'package:flutter/material.dart';

class UserManagementHeader extends StatelessWidget {
  const UserManagementHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main header
          Row(
            children: [
              Icon(
                Icons.admin_panel_settings,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                'Gebruikersrollenbeheer',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Beheer gebruikersrollen en demp gebruikers. Hosts en moderators kunnen rollen wijzigen en gebruikers dempen. Alle gebruikers worden getoond, inclusief verwijderde accounts.',
            style: const TextStyle(fontSize: 14, color: Colors.grey),
            textAlign: TextAlign.left,
            softWrap: true,
            overflow: TextOverflow.visible,
            maxLines: null,
          ),

          // Privacy warning section
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.orange.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.privacy_tip,
                      color: Colors.orange.shade700,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Privacy Waarschuwing',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Deze pagina bevat gevoelige persoonlijke gegevens. Bij gebruik van spraakfunctie: '
                  'zet volume laag of gebruik koptelefoon/oordopjes, vooral in openbare ruimtes.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                  softWrap: true,
                  overflow: TextOverflow.visible,
                  maxLines: null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
