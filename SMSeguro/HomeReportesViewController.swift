import UIKit

// =====================================================================
//  SMSeguro — Pantalla "home" (Lista de Reportes)
//
//  Archivo autónomo: no depende de ningún otro archivo del proyecto.
//  Arrástralo a Xcode, sigue los 4 pasos del final y listo.
// =====================================================================


// MARK: - Paleta

private enum Color {
    static let fondo     = UIColor(red: 0.10, green: 0.11, blue: 0.31, alpha: 1)  // azul marino
    static let tarjeta   = UIColor(red: 0.20, green: 0.21, blue: 0.44, alpha: 1)
    static let dorado    = UIColor(red: 0.79, green: 0.65, blue: 0.35, alpha: 1)
    static let texto     = UIColor.white
    static let textoSuave = UIColor.white.withAlphaComponent(0.72)
    static let fraude    = UIColor(red: 1.00, green: 0.42, blue: 0.42, alpha: 1)
    static let fraudeFondo = UIColor(red: 1.00, green: 0.23, blue: 0.19, alpha: 0.22)
    static let chipFondo = UIColor.white.withAlphaComponent(0.16)
}


// MARK: - Modelo

enum EstadoVerificacion: String, Codable {
    case confirmado  = "Confirmado como fraude"
    case enRevision  = "En revisión"
    case sinVerificar = "Sin verificar"

    var color: UIColor {
        switch self {
        case .confirmado:   return Color.fraude
        case .enRevision:   return Color.dorado
        case .sinVerificar: return Color.textoSuave
        }
    }

    var fondo: UIColor {
        switch self {
        case .confirmado:   return Color.fraudeFondo
        case .enRevision:   return Color.dorado.withAlphaComponent(0.20)
        case .sinVerificar: return Color.chipFondo
        }
    }
}

struct ReporteFraude {
    let id = UUID()
    var nombre: String
    var url: String
    var categoria: String
    var estado: EstadoVerificacion
    var mismoCaso: Int
    var comentarios: Int

    func coincide(con texto: String) -> Bool {
        guard !texto.isEmpty else { return true }
        return [nombre, url, categoria].contains {
            $0.range(of: texto, options: [.caseInsensitive, .diacriticInsensitive]) != nil
        }
    }
}


// MARK: - Celda (la tarjeta)

final class TarjetaReporteCell: UITableViewCell {

    static let reuseID = "TarjetaReporteCell"

    /// Se disparan al tocar los botones de abajo de la tarjeta.
    var alTocarMismoCaso: (() -> Void)?
    var alTocarComentarios: (() -> Void)?

    private let tarjeta = UIView()
    private let nombre = UILabel()
    private let url = UILabel()
    private let chipCategoria = PildoraLabel()
    private let chipEstado = PildoraLabel()
    private let btnMismoCaso = UIButton(type: .system)
    private let btnComentarios = UIButton(type: .system)

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        construir()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) no implementado") }

    private func construir() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none

        tarjeta.backgroundColor = Color.tarjeta
        tarjeta.layer.cornerRadius = 14
        tarjeta.layer.cornerCurve = .continuous
        tarjeta.translatesAutoresizingMaskIntoConstraints = false

        nombre.font = .systemFont(ofSize: 17, weight: .semibold)
        nombre.textColor = Color.texto
        nombre.numberOfLines = 2

        url.font = .systemFont(ofSize: 15, weight: .regular)
        url.textColor = Color.textoSuave
        url.numberOfLines = 1
        url.lineBreakMode = .byTruncatingMiddle

        // Fila de píldoras. El UIView() final las empuja a la izquierda.
        let filaChips = UIStackView(arrangedSubviews: [chipCategoria, chipEstado, UIView()])
        filaChips.axis = .horizontal
        filaChips.spacing = 8
        filaChips.alignment = .center

        configurarBoton(btnMismoCaso, simbolo: "exclamationmark.triangle", titulo: "Mismo caso")
        configurarBoton(btnComentarios, simbolo: "text.bubble", titulo: "Comentarios")
        btnMismoCaso.addTarget(self, action: #selector(tocarMismoCaso), for: .touchUpInside)
        btnComentarios.addTarget(self, action: #selector(tocarComentarios), for: .touchUpInside)

        let filaAcciones = UIStackView(arrangedSubviews: [btnMismoCaso, btnComentarios, UIView()])
        filaAcciones.axis = .horizontal
        filaAcciones.spacing = 20
        filaAcciones.alignment = .center

        let separador = UIView()
        separador.backgroundColor = UIColor.white.withAlphaComponent(0.10)
        separador.translatesAutoresizingMaskIntoConstraints = false
        separador.heightAnchor.constraint(equalToConstant: 1).isActive = true

        let contenido = UIStackView(arrangedSubviews: [
            nombre, url, filaChips, separador, filaAcciones
        ])
        contenido.axis = .vertical
        contenido.spacing = 8
        contenido.setCustomSpacing(4, after: nombre)
        contenido.setCustomSpacing(12, after: filaChips)
        contenido.setCustomSpacing(10, after: separador)
        contenido.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(tarjeta)
        tarjeta.addSubview(contenido)

        NSLayoutConstraint.activate([
            tarjeta.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            tarjeta.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),
            tarjeta.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            tarjeta.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),

            // Cadena completa arriba→abajo: por esto la celda calcula su altura sola.
            contenido.topAnchor.constraint(equalTo: tarjeta.topAnchor, constant: 14),
            contenido.bottomAnchor.constraint(equalTo: tarjeta.bottomAnchor, constant: -14),
            contenido.leadingAnchor.constraint(equalTo: tarjeta.leadingAnchor, constant: 14),
            contenido.trailingAnchor.constraint(equalTo: tarjeta.trailingAnchor, constant: -14)
        ])
    }

    private func configurarBoton(_ boton: UIButton, simbolo: String, titulo: String) {
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: simbolo)
        config.imagePadding = 6
        config.baseForegroundColor = Color.textoSuave
        config.contentInsets = .zero
        config.titleTextAttributesTransformer =
            UIConfigurationTextAttributesTransformer { entrada in
                var salida = entrada
                salida.font = .systemFont(ofSize: 14, weight: .regular)
                return salida
            }
        boton.configuration = config
        boton.setContentHuggingPriority(.required, for: .horizontal)
        // El título con el contador se pone en configurar(con:)
        boton.configuration?.title = titulo
    }

    func configurar(con reporte: ReporteFraude) {
        nombre.text = reporte.nombre
        url.text = reporte.url
        chipCategoria.aplicar(texto: reporte.categoria,
                              color: Color.texto,
                              fondo: Color.chipFondo)
        chipEstado.aplicar(texto: reporte.estado.rawValue,
                           color: reporte.estado.color,
                           fondo: reporte.estado.fondo)

        btnMismoCaso.configuration?.title =
            reporte.mismoCaso > 0 ? "Mismo caso · \(reporte.mismoCaso)" : "Mismo caso"
        btnComentarios.configuration?.title =
            reporte.comentarios > 0 ? "Comentarios · \(reporte.comentarios)" : "Comentarios"
    }

    @objc private func tocarMismoCaso()   { alTocarMismoCaso?() }
    @objc private func tocarComentarios() { alTocarComentarios?() }

    override func prepareForReuse() {
        super.prepareForReuse()
        alTocarMismoCaso = nil
        alTocarComentarios = nil
    }
}


// MARK: - Píldora reutilizable

final class PildoraLabel: UIView {

    private let etiqueta = UILabel()

    init() {
        super.init(frame: .zero)
        etiqueta.font = .systemFont(ofSize: 13, weight: .medium)
        etiqueta.translatesAutoresizingMaskIntoConstraints = false
        addSubview(etiqueta)
        NSLayoutConstraint.activate([
            etiqueta.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            etiqueta.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),
            etiqueta.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 9),
            etiqueta.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -9)
        ])
        layer.cornerRadius = 7
        layer.cornerCurve = .continuous
        setContentHuggingPriority(.required, for: .horizontal)
        setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) no implementado") }

    func aplicar(texto: String, color: UIColor, fondo: UIColor) {
        etiqueta.text = texto
        etiqueta.textColor = color
        backgroundColor = fondo
    }
}


// MARK: - Pantalla

final class HomeReportesViewController: UIViewController {

    // Cambia esto por tu fuente de datos real.
    private var todos: [ReporteFraude] = HomeReportesViewController.ejemplos
    private var visibles: [ReporteFraude] = []

    private let titulo = UILabel()
    private let botonAgregar = UIButton(type: .system)
    private let busqueda = UITextField()
    private let tabla = UITableView(frame: .zero, style: .plain)
    private let vacio = UILabel()

    // MARK: Ciclo de vida

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Color.fondo
        construir()
        filtrar()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Dibujamos nuestro propio título dorado, así que la barra de
        // navegación del Storyboard sobra.
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    // MARK: Construcción

    private func construir() {

        // --- Título ---
        titulo.text = "Reportes"
        titulo.font = .systemFont(ofSize: 34, weight: .bold)
        titulo.textColor = Color.dorado
        titulo.adjustsFontSizeToFitWidth = true
        titulo.minimumScaleFactor = 0.7

        // --- Botón + ---
        var configBoton = UIButton.Configuration.filled()
        configBoton.image = UIImage(systemName: "plus",
                                    withConfiguration: UIImage.SymbolConfiguration(
                                        pointSize: 18, weight: .semibold))
        configBoton.baseBackgroundColor = Color.dorado
        configBoton.baseForegroundColor = Color.fondo
        configBoton.cornerStyle = .capsule
        botonAgregar.configuration = configBoton
        botonAgregar.accessibilityLabel = "Nuevo reporte"
        botonAgregar.addTarget(self, action: #selector(nuevoReporte), for: .touchUpInside)

        // --- Búsqueda ---
        busqueda.placeholder = "Buscar por nombre o URL..."
        busqueda.font = .systemFont(ofSize: 16)
        busqueda.textColor = .black
        busqueda.backgroundColor = .white
        busqueda.layer.cornerRadius = 10
        busqueda.clearButtonMode = .whileEditing
        busqueda.returnKeyType = .search
        busqueda.autocapitalizationType = .none
        busqueda.autocorrectionType = .no
        busqueda.keyboardType = .webSearch
        busqueda.addTarget(self, action: #selector(filtrar), for: .editingChanged)

        // Padding interno: sin esto el texto queda pegado al borde.
        let padding = UIView(frame: CGRect(x: 0, y: 0, width: 14, height: 1))
        busqueda.leftView = padding
        busqueda.leftViewMode = .always

        // --- Tabla ---
        tabla.dataSource = self
        tabla.delegate = self
        tabla.register(TarjetaReporteCell.self,
                       forCellReuseIdentifier: TarjetaReporteCell.reuseID)
        tabla.backgroundColor = .clear
        tabla.separatorStyle = .none
        tabla.rowHeight = UITableView.automaticDimension
        tabla.estimatedRowHeight = 140
        tabla.keyboardDismissMode = .onDrag
        tabla.showsVerticalScrollIndicator = false
        tabla.contentInset = UIEdgeInsets(top: 6, left: 0, bottom: 24, right: 0)

        // --- Estado vacío ---
        vacio.text = "Ningún reporte coincide con tu búsqueda."
        vacio.font = .systemFont(ofSize: 16)
        vacio.textColor = Color.textoSuave
        vacio.textAlignment = .center
        vacio.numberOfLines = 0
        vacio.isHidden = true

        [titulo, botonAgregar, busqueda, tabla, vacio].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }

        let safe = view.safeAreaLayoutGuide

        NSLayoutConstraint.activate([
            // El título va al SAFE AREA. Este era el error de tu Storyboard:
            // anclado al Superview se metía debajo de la isla dinámica.
            titulo.topAnchor.constraint(equalTo: safe.topAnchor, constant: 12),
            titulo.leadingAnchor.constraint(equalTo: safe.leadingAnchor, constant: 20),

            // El + se alinea al CENTRO del título, no a otra referencia.
            // Así los dos se mueven juntos pase lo que pase.
            botonAgregar.centerYAnchor.constraint(equalTo: titulo.centerYAnchor),
            botonAgregar.leadingAnchor.constraint(greaterThanOrEqualTo: titulo.trailingAnchor,
                                                  constant: 12),
            botonAgregar.trailingAnchor.constraint(equalTo: safe.trailingAnchor, constant: -20),
            botonAgregar.widthAnchor.constraint(equalToConstant: 44),
            botonAgregar.heightAnchor.constraint(equalToConstant: 44),

            busqueda.topAnchor.constraint(equalTo: titulo.bottomAnchor, constant: 14),
            busqueda.leadingAnchor.constraint(equalTo: safe.leadingAnchor, constant: 20),
            busqueda.trailingAnchor.constraint(equalTo: safe.trailingAnchor, constant: -20),
            busqueda.heightAnchor.constraint(equalToConstant: 44),

            tabla.topAnchor.constraint(equalTo: busqueda.bottomAnchor, constant: 16),
            tabla.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tabla.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            // Al Safe Area: así el Tab Bar nunca tapa la última tarjeta.
            tabla.bottomAnchor.constraint(equalTo: safe.bottomAnchor),

            vacio.centerYAnchor.constraint(equalTo: tabla.centerYAnchor),
            vacio.leadingAnchor.constraint(equalTo: safe.leadingAnchor, constant: 40),
            vacio.trailingAnchor.constraint(equalTo: safe.trailingAnchor, constant: -40)
        ])

        // El título cede antes que el botón si el espacio se aprieta.
        titulo.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        botonAgregar.setContentHuggingPriority(.required, for: .horizontal)

        let toque = UITapGestureRecognizer(target: self, action: #selector(cerrarTeclado))
        toque.cancelsTouchesInView = false
        view.addGestureRecognizer(toque)
    }

    // MARK: Datos

    @objc private func filtrar() {
        let texto = busqueda.text ?? ""
        visibles = todos.filter { $0.coincide(con: texto) }
        tabla.reloadData()
        vacio.isHidden = !visibles.isEmpty
    }

    // MARK: Acciones

    @objc private func nuevoReporte() {
        // Conecta aquí tu pantalla de alta.
        let alerta = UIAlertController(title: "Nuevo reporte",
                                       message: "Aquí va tu pantalla de alta.",
                                       preferredStyle: .alert)
        alerta.addAction(UIAlertAction(title: "Entendido", style: .default))
        present(alerta, animated: true)
    }

    @objc private func cerrarTeclado() {
        view.endEditing(true)
    }

    private func marcarMismoCaso(_ reporte: ReporteFraude) {
        guard let i = todos.firstIndex(where: { $0.id == reporte.id }) else { return }
        todos[i].mismoCaso += 1
        filtrar()
    }

    // MARK: Datos de ejemplo

    private static var ejemplos: [ReporteFraude] {
        [
            ReporteFraude(nombre: "iPhone 15 a mitad de precio",
                          url: "wwww.macIphone15-mx.com",
                          categoria: "Electrónicos",
                          estado: .confirmado, mismoCaso: 34, comentarios: 12),
            ReporteFraude(nombre: "Hotel en Cancún con 80% de descuento",
                          url: "reservas-cancun-vip.net",
                          categoria: "Hoteles",
                          estado: .confirmado, mismoCaso: 21, comentarios: 8),
            ReporteFraude(nombre: "PlayStation 5 con envío gratis",
                          url: "ofertas-ps5-mexico.shop",
                          categoria: "Electrónicos",
                          estado: .enRevision, mismoCaso: 5, comentarios: 3),
            ReporteFraude(nombre: "Préstamo inmediato sin buró",
                          url: "credito-rapido-24h.com.mx",
                          categoria: "Servicios",
                          estado: .confirmado, mismoCaso: 57, comentarios: 19),
            ReporteFraude(nombre: "Boletos de avión a mitad de precio",
                          url: "vuelosbaratos-promo.info",
                          categoria: "Viajes",
                          estado: .sinVerificar, mismoCaso: 1, comentarios: 0)
        ]
    }
}


// MARK: - Tabla

extension HomeReportesViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        visibles.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        guard let celda = tableView.dequeueReusableCell(
                withIdentifier: TarjetaReporteCell.reuseID,
                for: indexPath) as? TarjetaReporteCell else {
            return UITableViewCell()
        }

        let reporte = visibles[indexPath.row]
        celda.configurar(con: reporte)
        celda.alTocarMismoCaso = { [weak self] in self?.marcarMismoCaso(reporte) }
        celda.alTocarComentarios = { [weak self] in
            self?.mostrarPendiente("Comentarios de \"\(reporte.nombre)\"")
        }
        return celda
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        mostrarPendiente("Detalle de \"\(visibles[indexPath.row].nombre)\"")
    }

    private func mostrarPendiente(_ mensaje: String) {
        let alerta = UIAlertController(title: mensaje, message: nil, preferredStyle: .alert)
        alerta.addAction(UIAlertAction(title: "Entendido", style: .default))
        present(alerta, animated: true)
    }
}


// =====================================================================
//  CÓMO CONECTARLO EN TU PROYECTO (4 pasos)
//
//  1. Arrastra este archivo a Xcode, dentro de la carpeta SMSeguro.
//
//  2. Abre Main.storyboard y selecciona la escena "home".
//     En el árbol de la izquierda, borra TODO lo que está dentro de "View":
//     el label "Reportes", el botón "+", el text field, el Scroll View y
//     sus Stack Views. Deja el "View" vacío (Safe Area se queda).
//
//  3. Con el View Controller "home" seleccionado, ve al Identity Inspector
//     (el ícono del cuadrito, tercero de la derecha) y en "Class" escribe:
//         HomeReportesViewController
//     Presiona Enter. Debe quedar con Module: SMSeguro.
//
//  4. Corre. Los 6 warnings desaparecen porque ya no hay Scroll View
//     ambiguo en el Storyboard.
//
//  Los demás tabs (Dashboard, Tips, Profile) no se tocan.
// =====================================================================
