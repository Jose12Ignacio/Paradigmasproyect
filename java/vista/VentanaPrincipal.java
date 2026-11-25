package vista;

import javax.swing.*;
import javax.swing.border.TitledBorder;
import java.awt.*;

public class VentanaPrincipal extends JFrame {

    public VentanaPrincipal() {
        // Configuración básica de la ventana
        setTitle("CEmestre - Constructor de Horarios");
        setSize(1200, 800);
        setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
        setLocationRelativeTo(null); // Centrar en pantalla
        setLayout(new BorderLayout(10, 10));

        // --- PANEL IZQUIERDO: Lista de Combinaciones y Filtros ---
        JPanel panelIzquierdo = new JPanel(new BorderLayout(5, 5));
        panelIzquierdo.setPreferredSize(new Dimension(350, 0));
        panelIzquierdo.setBorder(BorderFactory.createEmptyBorder(10, 10, 10, 10));

        // 1. Selector de Criterio de Orden (JComboBox)
        JPanel panelOrden = new JPanel(new FlowLayout(FlowLayout.LEFT));
        panelOrden.add(new JLabel("Ordenar por:"));
        String[] criterios = {"Menos días en el TEC", "Menos huecos", "Hora promedio de inicio", "Criterio del Grupo"};
        JComboBox<String> comboOrden = new JComboBox<>(criterios);
        panelOrden.add(comboOrden);
        panelIzquierdo.add(panelOrden, BorderLayout.NORTH);

        // 2. Lista de Combinaciones (JList con scroll)
        DefaultListModel<String> modeloLista = new DefaultListModel<>();
        modeloLista.addElement("Combinación Válida #1 (12 créditos)");
        modeloLista.addElement("Combinación Válida #2 (10 créditos)");
        modeloLista.addElement("Combinación Rechazada #1 (Razón: Balance de carreras)");
        modeloLista.addElement("Combinación Rechazada #2 (Razón: Límite por área)");
        
        JList<String> listaCombinaciones = new JList<>(modeloLista);
        listaCombinaciones.setSelectionMode(ListSelectionModel.SINGLE_SELECTION);
        JScrollPane scrollLista = new JScrollPane(listaCombinaciones);
        scrollLista.setBorder(BorderFactory.createTitledBorder(
                BorderFactory.createEtchedBorder(), "Combinaciones (Válidas y Rechazadas)", TitledBorder.LEFT, TitledBorder.TOP));
        panelIzquierdo.add(scrollLista, BorderLayout.CENTER);

        add(panelIzquierdo, BorderLayout.WEST);

        // --- PANEL CENTRAL/DERECHO: Visualización del Horario ---
        JPanel panelHorario = new JPanel(new BorderLayout());
        panelHorario.setBorder(BorderFactory.createTitledBorder(
                BorderFactory.createEtchedBorder(), "Horario Semanal", TitledBorder.LEFT, TitledBorder.TOP));
        
        JLabel placeholderHorario = new JLabel("Seleccione una combinación para ver el horario", SwingConstants.CENTER);
        placeholderHorario.setFont(new Font("Arial", Font.ITALIC, 16));
        panelHorario.add(placeholderHorario, BorderLayout.CENTER);

        add(panelHorario, BorderLayout.CENTER);

        // --- BARRA DE ESTADO ---
        JLabel barraEstado = new JLabel(" Listo. Cargue los archivos de Prolog para comenzar.");
        barraEstado.setBorder(BorderFactory.createEtchedBorder());
        add(barraEstado, BorderLayout.SOUTH);
    }
}