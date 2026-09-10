import UIKit
import PhotosUI

// =====================================================================
//  SMSeguro — Pantalla "Detalle Reporte"
//
//  Es la hermana de NuevoReporteViewController. Hace lo mismo:
//    1. El selector de Categoría (lista desplegable)
//    2. La foto de evidencia (cámara o galería)
//    3. Botón "Actualizar reporte"
//    4. Botón "Eliminar" (con confirmación)
//    5. Muestra el estado de validación del reporte
//
// =====================================================================

final class DetalleReporteViewController: UIViewController {

    // MARK: - Conexiones al Storyboard

    /// Botón "Selecciona una opción"
    @IBOutlet weak var botonCategoria: UIButton!

    /// Botón grande "Toma foto o sube imagen"
    @IBOutlet weak var botonFoto: UIButton!

    // --- Los de abajo son opcionales: si todavía no los conectas, no truena. ---

    /// Etiqueta roja: "Confirmado como fraude"
    @IBOutlet weak var etiquetaEstado: UILabel?

    /// Etiqueta gris: "Asignado por nuestro equipo de verificación."
    @IBOutlet weak var etiquetaDetalleEstado: UILabel?

    /// Campo "https://sitio-sospechoso.com/oferta"
    @IBOutlet weak var campoURL: UITextField?

    /// Caja de texto "Describe brevemente qué encontraste..."
    @IBOutlet weak var campoDescripcion: UITextView?

    // MARK: - Acciones del Storyboard

    /// Flecha ← de arriba
    @IBAction func cerrarPantalla(_ sender: Any) {
        dismiss(animated: true)
    }

    /// Botón "Actualizar reporte"
    @IBAction func actualizarReporte(_ sender: Any) {
        guard validarCampos() else { return }

        // Aquí guardarías los cambios (base de datos, API, arreglo, etc.).
        // Por ahora solo confirmamos al usuario.
        avisar(titulo: "Reporte actualizado",
               mensaje: "Los cambios se guardaron correctamente.") { [weak self] in
            self?.dismiss(animated: true)
        }
    }

    /// Botón "Eliminar"
    @IBAction func eliminarReporte(_ sender: Any) {
        let alerta = UIAlertController(
            title: "¿Eliminar este reporte?",
            message: "Esta acción no se puede deshacer.",
            preferredStyle: .alert
        )

        alerta.addAction(UIAlertAction(title: "Cancelar", style: .cancel))
        alerta.addAction(UIAlertAction(title: "Eliminar", style: .destructive) { [weak self] _ in
            // Aquí borrarías el reporte de verdad.
            self?.dismiss(animated: true)
        })

        present(alerta, animated: true)
    }

    // MARK: - Configuración

    private let categorias = [
        "Hoteles y viajes",
        "Electrónicos",
        "Empleos",
        "Vehículos",
        "Boletos para eventos"
    ]

    private let alturaOpcion: CGFloat = 44
    private let tamañoLetra: CGFloat = 16
    private let colorFondoOpcion = UIColor(red: 0.91, green: 0.91, blue: 0.92, alpha: 1)

    // MARK: - Estado

    private var botonesOpcion: [UIButton] = []
    private var desplegado = false

    /// Lo que el usuario eligió.
    private(set) var categoriaSeleccionada: String?
    private(set) var fotoSeleccionada: UIImage?

    // MARK: - Ciclo de vida

    override func viewDidLoad() {
        super.viewDidLoad()
        prepararSelector()
        prepararBotonFoto()
    }


    // =================================================================
    //  MARK: - Selector de categoría
    // =================================================================

    private func prepararSelector() {
        guard let stack = botonCategoria.superview as? UIStackView,
              let indice = stack.arrangedSubviews.firstIndex(of: botonCategoria)
        else {
            print("⚠️ El botón de categoría no está dentro de un Stack View.")
            return
        }

        botonCategoria.addTarget(self, action: #selector(alternarLista),
                                 for: .touchUpInside)

        for (i, nombre) in categorias.enumerated() {
            let opcion = crearOpcion(titulo: nombre)
            opcion.tag = i
            opcion.addTarget(self, action: #selector(elegirCategoria(_:)),
                             for: .touchUpInside)
            opcion.isHidden = true
            opcion.alpha = 0

            botonesOpcion.append(opcion)
            stack.insertArrangedSubview(opcion, at: indice + 1 + i)
        }
    }

    private func crearOpcion(titulo: String) -> UIButton {
        let boton = UIButton(type: .system)

        var config = UIButton.Configuration.filled()
        config.title = titulo
        config.baseBackgroundColor = colorFondoOpcion
        config.baseForegroundColor = .black
        config.cornerStyle = .fixed
        config.background.cornerRadius = 8
        config.titleTextAttributesTransformer =
            UIConfigurationTextAttributesTransformer { [weak self] entrada in
                var salida = entrada
                salida.font = .systemFont(ofSize: self?.tamañoLetra ?? 16)
                return salida
            }
        boton.configuration = config

        boton.heightAnchor.constraint(equalToConstant: alturaOpcion).isActive = true
        return boton
    }

    @objc private func alternarLista() {
        desplegado.toggle()
        animarOpciones(visibles: desplegado)
    }

    @objc private func elegirCategoria(_ boton: UIButton) {
        let elegida = categorias[boton.tag]
        categoriaSeleccionada = elegida
        ponerTitulo(elegida, en: botonCategoria, color: .black)

        desplegado = false
        animarOpciones(visibles: false)
    }

    private func animarOpciones(visibles: Bool) {
        UIView.animate(withDuration: 0.25) {
            self.botonesOpcion.forEach {
                $0.isHidden = !visibles
                $0.alpha = visibles ? 1 : 0
            }
            self.view.layoutIfNeeded()
        }
    }


    // =================================================================
    //  MARK: - Foto de evidencia
    // =================================================================

    private func prepararBotonFoto() {
        botonFoto.addTarget(self, action: #selector(tocarFoto), for: .touchUpInside)
        // La foto se recorta para llenar el recuadro sin deformarse.
        botonFoto.configuration?.background.imageContentMode = .scaleAspectFill
        botonFoto.clipsToBounds = true
    }

    @objc private func tocarFoto() {
        let hoja = UIAlertController(title: "Foto de evidencia",
                                     message: nil,
                                     preferredStyle: .actionSheet)

        // La cámara solo existe en dispositivos reales.
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            hoja.addAction(UIAlertAction(title: "Tomar foto", style: .default) { [weak self] _ in
                self?.abrirCamara()
            })
        }

        hoja.addAction(UIAlertAction(title: "Elegir de la galería", style: .default) { [weak self] _ in
            self?.abrirGaleria()
        })

        if fotoSeleccionada != nil {
            hoja.addAction(UIAlertAction(title: "Quitar foto", style: .destructive) { [weak self] _ in
                self?.mostrarFoto(nil)
            })
        }

        hoja.addAction(UIAlertAction(title: "Cancelar", style: .cancel))

        // Necesario para que no truene en iPad.
        hoja.popoverPresentationController?.sourceView = botonFoto
        hoja.popoverPresentationController?.sourceRect = botonFoto.bounds

        present(hoja, animated: true)
    }

    private func abrirCamara() {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = self
        picker.allowsEditing = true
        present(picker, animated: true)
    }

    private func abrirGaleria() {
        // PHPickerViewController es el selector moderno: no pide permisos
        // y el usuario solo comparte la foto que elige.
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }

    /// Pasa `nil` para volver al estado inicial.
    private func mostrarFoto(_ imagen: UIImage?) {
        fotoSeleccionada = imagen

        if let imagen {
            botonFoto.configuration?.background.image = imagen
            botonFoto.configuration?.title = nil
            botonFoto.configuration?.image = nil
        } else {
            botonFoto.configuration?.background.image = nil
            botonFoto.configuration?.title = "Toma foto o sube imagen"
            botonFoto.configuration?.image = UIImage(systemName: "camera.fill")
        }
    }


    // =================================================================
    //  MARK: - Utilidades
    // =================================================================

    private func ponerTitulo(_ texto: String, en boton: UIButton, color: UIColor) {
        if boton.configuration != nil {
            boton.configuration?.title = texto
            boton.configuration?.baseForegroundColor = color
        } else {
            boton.setTitle(texto, for: .normal)
            boton.setTitleColor(color, for: .normal)
        }
    }

    /// Revisa que la URL no esté vacía antes de actualizar.
    private func validarCampos() -> Bool {
        let url = campoURL?.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        // Si el campo ni siquiera está conectado, no bloqueamos nada.
        guard campoURL != nil else { return true }

        if url.isEmpty {
            avisar(titulo: "Falta la URL",
                   mensaje: "Escribe la dirección de la oferta falsa.")
            return false
        }
        return true
    }

    private func avisar(titulo: String,
                        mensaje: String,
                        alCerrar: (() -> Void)? = nil) {
        let alerta = UIAlertController(title: titulo,
                                       message: mensaje,
                                       preferredStyle: .alert)
        alerta.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            alCerrar?()
        })
        present(alerta, animated: true)
    }
}


// MARK: - Cámara

extension DetalleReporteViewController: UIImagePickerControllerDelegate,
                                        UINavigationControllerDelegate {

    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        picker.dismiss(animated: true)
        let imagen = (info[.editedImage] as? UIImage) ?? (info[.originalImage] as? UIImage)
        if let imagen { mostrarFoto(imagen) }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}


// MARK: - Galería

extension DetalleReporteViewController: PHPickerViewControllerDelegate {

    func picker(_ picker: PHPickerViewController,
                didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)

        guard let proveedor = results.first?.itemProvider,
              proveedor.canLoadObject(ofClass: UIImage.self) else { return }

        proveedor.loadObject(ofClass: UIImage.self) { [weak self] objeto, error in
            guard let imagen = objeto as? UIImage else {
                if let error { print("No se pudo cargar la imagen:", error) }
                return
            }
            // La carga ocurre en segundo plano; la interfaz se toca en el hilo principal.
            DispatchQueue.main.async {
                self?.mostrarFoto(imagen)
            }
        }
    }
}


// =====================================================================
//  CÓMO CONECTARLO
//
//  1. Arrastra este archivo a tu proyecto (o crea uno nuevo con
//     File → New → File → Swift File y pega el contenido).
//
//  2. En el Storyboard, selecciona el View Controller de Detalle
//     Reporte → Identity Inspector → Class = DetalleReporteViewController
//
//  3. Ve al Connections Inspector y conecta, uno por uno,
//     Ctrl+arrastrando desde el círculo amarillo hacia cada elemento:
//
//        botonCategoria   → botón "Selecciona una opción"
//        botonFoto        → botón "Toma foto o sube imagen"
//
//     Y desde cada botón hacia el círculo amarillo, para las acciones:
//
//        flecha ←              → cerrarPantalla:
//        "Actualizar reporte"  → actualizarReporte:
//        "Eliminar"            → eliminarReporte:
//
//     Los cuatro outlets opcionales (etiquetaEstado, etiquetaDetalleEstado,
//     campoURL, campoDescripcion) puedes dejarlos sin conectar por ahora;
//     no truena. Conéctalos cuando quieras leer o cambiar esos valores.
//
//  4. Corre con Cmd+R.
// =====================================================================
